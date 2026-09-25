import "dart:async";

import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/active_wallet_service.dart";
import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/decred/decred.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/reactions/wallet_utils.dart" as wallet_utils;
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/zano/zano.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/spl_token.dart";
import "package:cw_core/tron_token.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:mobx/mobx.dart" as mobx;

class AddressServiceException implements Exception {
  const AddressServiceException(this.message);

  final String message;

  @override
  String toString() => "AddressServiceException: $message";
}

class AddressService {
  AddressService({
    required ActiveWalletService activeWalletService,
    required SettingsStore settingsStore,
  })  : _activeWalletService = activeWalletService,
        _settingsStore = settingsStore {
    _walletSub = activeWalletService.walletChanges.listen((_) => _bindPayjoin());
    _bindPayjoin();
  }

  final ActiveWalletService _activeWalletService;
  final SettingsStore _settingsStore;

  final _payjoinController = StreamController<String?>.broadcast();
  late final StreamSubscription<WalletBase> _walletSub;
  mobx.ReactionDisposer? _payjoinDisposer;

  WalletBase get wallet => _activeWalletService.wallet;

  List<CryptoCurrency> get receivableTokens =>
      wallet.balance.keys.whereType<CryptoCurrency>().toList();

  bool get hasTokens => wallet_utils.hasTokens(wallet.type);

  bool get hasAccounts => wallet.type == WalletType.monero;

  List<AddressGroup> computeAddressList() {
    final type = wallet.type;

    if (type == WalletType.monero) {
      return [_moneroAddresses()];
    }
    if (_isElectrumType(type)) {
      return _electrumAddresses();
    }
    if (isEVMCompatibleChain(type)) {
      return _singleAddressGroup(evm!.getAddress(wallet));
    }
    if (type == WalletType.solana) {
      return _singleAddressGroup(solana!.getAddress(wallet));
    }
    if (type == WalletType.tron) {
      return _singleAddressGroup(tron!.getAddress(wallet));
    }
    if (type == WalletType.nano) {
      return _singleAddressGroup(wallet.walletAddresses.address);
    }
    if (type == WalletType.zano) {
      return _singleAddressGroup(zano!.getAddress(wallet));
    }
    if (type == WalletType.decred) {
      return [_decredAddresses()];
    }
    if (type == WalletType.zcash) {
      return [_zcashAddresses()];
    }

    return const [];
  }

  AddressGroup _moneroAddresses() {
    final wallet = this.wallet;
    final subaddresses = monero!.getSubaddressList(wallet).subaddresses;
    final entries = subaddresses
        .map(
          (s) => AddressEntry(
            id: s.id,
            address: s.address,
            label: s.label,
            txCount: s.txCount,
            balance: Money.tryParse(s.received ?? "", CryptoCurrency.xmr),
            isHidden: wallet.walletAddresses.hiddenAddresses.contains(s.address),
          ),
        )
        .toList();
    return AddressGroup(entries: entries);
  }

  List<AddressGroup> _electrumAddresses() {
    final wallet = this.wallet;
    if (bitcoin!.hasSelectedSilentPayments(wallet)) {
      final main = bitcoin!.getSilentPaymentAddresses(wallet).map(_electrumEntry).toList();
      final received =
          bitcoin!.getSilentPaymentReceivedAddresses(wallet).map(_electrumEntry).toList();
      return [
        AddressGroup(entries: main),
        AddressGroup(header: const SilentPaymentsReceivedHeader(), entries: received),
      ];
    }

    var entries = bitcoin!.getSubAddresses(wallet).map(_electrumEntry).toList();

    if (wallet.type == WalletType.litecoin && entries.length >= _mwebTruncationThreshold) {
      var index = entries.lastIndexWhere((e) => (e.txCount ?? 0) > 0);
      if (index == -1) {
        index = 0;
      }
      final upperBound = index + _mwebTruncationTrailingBuffer;
      entries = entries.sublist(0, upperBound < entries.length ? upperBound : entries.length);
    }

    return [AddressGroup(entries: entries)];
  }

  static const _mwebTruncationThreshold = 1000;
  static const _mwebTruncationTrailingBuffer = 20;

  AddressEntry _electrumEntry(ElectrumSubAddress addr) {
    final wallet = this.wallet;
    final hidden = wallet.walletAddresses.hiddenAddresses.contains(addr.address) ||
        (wallet.type == WalletType.bitcoin && addr.isLegacyDerivation);
    return AddressEntry(
      id: addr.id,
      address: addr.address,
      label: addr.name,
      txCount: addr.txCount,
      balance: Money.fromInt(addr.balance, walletTypeToCryptoCurrency(wallet.type)),
      derivationPath: addr.derivationPath,
      isHidden: hidden,
    );
  }

  AddressGroup _decredAddresses() {
    final wallet = this.wallet;
    final entries = decred!
        .getAddressInfos(wallet)
        .map(
          (i) => AddressEntry(
            address: i.address,
            label: i.label,
            isHidden: wallet.walletAddresses.hiddenAddresses.contains(i.address),
          ),
        )
        .toList();
    return AddressGroup(entries: entries);
  }

  AddressGroup _zcashAddresses() {
    final wallet = this.wallet;
    final entries = zcash!
        .getAddressInfos(wallet)
        .map(
          (i) => AddressEntry(
            id: i.mapKey,
            address: i.address,
            label: i.label,
            isHidden: wallet.walletAddresses.hiddenAddresses.contains(i.address),
          ),
        )
        .toList();
    return AddressGroup(entries: entries);
  }

  List<AddressGroup> _singleAddressGroup(String address) => [
        AddressGroup(entries: [AddressEntry(address: address)]),
      ];

  String get currentAddress => wallet.walletAddresses.address;

  Future<void> setActiveAddress(String address) async {
    wallet.walletAddresses.address = address;
  }

  Future<void> rotateAddress() async {
    final wallet = this.wallet;
    final newAddress = await _generateNewAddress(wallet, "");
    wallet.walletAddresses.address = newAddress;
    if (wallet.walletAddresses.address != newAddress) {
      throw AddressServiceException("${wallet.type} did not switch to $newAddress");
    }
  }

  Future<void> addManualAddress(String label) => _generateNewAddress(wallet, label);

  Future<String> _generateNewAddress(WalletBase wallet, String label) async {
    final type = wallet.type;

    if (_isElectrumType(type)) {
      final address = await bitcoin!.generateNewAddress(wallet, label);
      return _requireAddress(address, type);
    }

    if (type == WalletType.decred) {
      final address = _requireAddress(await decred!.generateNewAddress(wallet, label), type);
      await wallet.save();
      return address;
    }

    if (type == WalletType.monero) {
      final accountIndex = monero!.getCurrentAccount(wallet).id;
      final beforeIds = monero!.getSubaddressList(wallet).subaddresses.map((s) => s.id).toSet();
      await monero!.getSubaddressList(wallet).addSubaddress(
            wallet,
            accountIndex: accountIndex,
            label: label,
          );
      final subs = monero!.getSubaddressList(wallet).subaddresses;
      final fresh = subs.where((s) => !beforeIds.contains(s.id)).firstOrNull;
      if (fresh == null) {
        throw AddressServiceException("monero added no subaddress to account $accountIndex");
      }
      wallet.walletAddresses.manualAddresses.add(fresh.address);
      await wallet.save();
      return fresh.address;
    }

    throw AddressServiceException("address generation is not supported for $type");
  }

  String _requireAddress(String address, WalletType type) {
    if (address.isEmpty) {
      throw AddressServiceException("$type returned an empty address");
    }
    return address;
  }

  Future<void> setLabel(AddressEntry entry, String label) async {
    final wallet = this.wallet;
    final type = wallet.type;

    if (_isElectrumType(type)) {
      await bitcoin!.updateAddress(wallet, entry.address, label);
      return;
    }

    if (type == WalletType.decred) {
      await decred!.updateAddress(wallet, entry.address, label);
      await wallet.save();
      return;
    }

    if (type == WalletType.monero) {
      final index = entry.id;
      if (index == null) {
        throw AddressServiceException("monero subaddress ${entry.address} has no index");
      }
      await monero!.getSubaddressList(wallet).setLabelSubaddress(
            wallet,
            accountIndex: monero!.getCurrentAccount(wallet).id,
            addressIndex: index,
            label: label,
          );
      await wallet.save();
      return;
    }

    throw AddressServiceException("address labels are not supported for $type");
  }

  bool get canSetLabel {
    final type = wallet.type;
    return _isElectrumType(type) || type == WalletType.decred || type == WalletType.monero;
  }

  bool get canHide => wallet.type != WalletType.zcash;

  Future<void> setHidden(String address, {required bool hidden}) async {
    final wallet = this.wallet;
    if (hidden) {
      wallet.walletAddresses.hiddenAddresses.add(address);
    } else {
      wallet.walletAddresses.hiddenAddresses.removeWhere((e) => e == address);
    }

    await wallet.walletAddresses.saveAddressesInBox();

    if (wallet.type == WalletType.monero) {
      await monero!.getSubaddressList(wallet).update(
            wallet,
            accountIndex: monero!.getCurrentAccount(wallet).id,
          );
    }
  }

  ReceivePageOption get selectedAddressType {
    final type = wallet.type;
    if (type == WalletType.bitcoin || type == WalletType.litecoin) {
      return bitcoin!.getSelectedAddressType(wallet);
    }
    if (type == WalletType.zcash) {
      return zcash!.getSelectedAddressType(wallet);
    }
    return addressTypeOptions.firstOrNull ?? ReceivePageOption.mainnet;
  }

  List<ReceivePageOption> get addressTypeOptions =>
      wallet.walletAddresses.receivePageOptions.where(wallet.receiveOptionAvailable).toList();

  Future<void> setAddressType(ReceivePageOption option) => _setAddressTypeOn(wallet, option);

  Future<void> _setAddressTypeOn(WalletBase wallet, ReceivePageOption option) async {
    final type = wallet.type;
    if (type == WalletType.bitcoin || type == WalletType.litecoin) {
      await bitcoin!.setAddressType(wallet, bitcoin!.getOptionToType(option));
      return;
    }
    if (type == WalletType.zcash) {
      await zcash!.setAddressType(wallet, zcash!.getOptionToType(option));
    }
  }

  PaymentURI buildPaymentUri({Money? amount, CryptoCurrency? token}) {
    final type = wallet.type;
    final address = wallet.walletAddresses.address;
    final rawAmount = amount?.toStringWithPrecision() ?? "";

    if (token is Erc20Token && isEVMCompatibleChain(type)) {
      return ERC681URI(
        chainId: wallet.chainId ?? 1,
        address: address,
        amount: rawAmount,
        contractAddress: token.contractAddress,
        tokenDecimals: token.decimal,
      );
    }
    if (token is TronToken && type == WalletType.tron) {
      return TronURI(
        amount: rawAmount,
        address: address,
        contractAddress: token.contractAddress,
      );
    }
    if (token is SPLToken && type == WalletType.solana) {
      return SolanaURI(
        amount: rawAmount,
        address: address,
        contractAddress: token.mintAddress,
      );
    }
    return wallet.walletAddresses.getPaymentUri(rawAmount);
  }

  Future<PaymentURI> fetchPaymentRequestUri({Money? amount, CryptoCurrency? token}) async {
    if (token is Erc20Token || token is TronToken || token is SPLToken) {
      return buildPaymentUri(amount: amount, token: token);
    }
    return wallet.walletAddresses.getPaymentRequestUri(amount?.toStringWithPrecision() ?? "");
  }

  Stream<String?> get payjoinEndpointChanges => _payjoinController.stream;

  void _bindPayjoin() {
    _payjoinDisposer?.call();
    _payjoinDisposer = null;

    final WalletType type;
    try {
      type = this.wallet.type;
    } on StateError {
      return;
    }

    if (type != WalletType.bitcoin) {
      _emitPayjoin(null);
      return;
    }

    final wallet = this.wallet;
    _emitPayjoin(_emptyToNull(bitcoin!.getPayjoinEndpoint(wallet)));

    _payjoinDisposer = mobx.reaction<String>(
      (_) => bitcoin!.getPayjoinEndpoint(wallet),
      (value) => _emitPayjoin(_emptyToNull(value)),
    );
  }

  void _emitPayjoin(String? value) {
    if (_payjoinController.isClosed) {
      return;
    }
    _payjoinController.add(value);
  }

  String? _emptyToNull(String value) => value.isEmpty ? null : value;

  Future<void> dispose() async {
    _payjoinDisposer?.call();
    _payjoinDisposer = null;
    await _walletSub.cancel();
    await _payjoinController.close();
  }

  bool get isAutoGenerateSubaddressEnabled {
    if (isSilentPayments) {
      return false;
    }
    return _settingsStore.autoGenerateSubaddressStatus != AutoGenerateSubaddressStatus.disabled;
  }

  AutoGenerateSubaddressStatus get autoGenerateSubaddressStatus =>
      _settingsStore.autoGenerateSubaddressStatus;

  void applyAutoGenerateOverride() {
    if (!wallet.isEnabledAutoGenerateSubaddress) {
      return;
    }
    final latestAddress = wallet.walletAddresses.latestAddress;
    if (latestAddress.isNotEmpty) {
      wallet.walletAddresses.address = latestAddress;
    }
  }

  Future<void> applyOpenDefaults({required bool lightningMode}) async {
    final wallet = this.wallet;
    if (wallet.type != WalletType.bitcoin) {
      return;
    }

    final lightning = bitcoin!.getBitcoinLightningReceivePageOption();
    final target = lightningMode && addressTypeOptions.contains(lightning)
        ? lightning
        : bitcoin!.getBitcoinSegwitPageOption();
    if (bitcoin!.getSelectedAddressType(wallet) != target) {
      await _setAddressTypeOn(wallet, target);
    }
  }

  bool get isSilentPayments =>
      wallet.type == WalletType.bitcoin && bitcoin!.hasSelectedSilentPayments(wallet);

  bool get isZCashTransparent {
    if (wallet.type != WalletType.zcash) {
      return true;
    }
    return zcash!.hasSelectedTransparentAddress(wallet);
  }

  String get accountLabel =>
      wallet.type == WalletType.monero ? monero!.getCurrentAccount(wallet).label : "";

  bool _isElectrumType(WalletType type) =>
      type == WalletType.bitcoin ||
      type == WalletType.litecoin ||
      type == WalletType.bitcoinCash ||
      type == WalletType.dogecoin;
}
