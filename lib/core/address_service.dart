import "dart:async";

import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/core/amount_parsing_proxy.dart";
import "package:cake_wallet/decred/decred.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/wownero/wownero.dart";
import "package:cake_wallet/zano/zano.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/spl_token.dart";
import "package:cw_core/tron_token.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:mobx/mobx.dart" as mobx;

class AddressService {
  AddressService({
    required WalletBase Function() wallet,
    required Stream<WalletBase> walletChanges,
    required SettingsStore settingsStore,
    required AmountParsingProxy Function() amountParsingProxyGetter,
  })  : _wallet = wallet,
        _settingsStore = settingsStore,
        _amountParsingProxyGetter = amountParsingProxyGetter {
    _walletSub = walletChanges.listen((_) => _bindPayjoin());
    _bindPayjoin();
  }

  final WalletBase Function() _wallet;
  final SettingsStore _settingsStore;
  final AmountParsingProxy Function() _amountParsingProxyGetter;

  final _payjoinController = StreamController<String?>.broadcast();
  late final StreamSubscription<WalletBase> _walletSub;
  mobx.ReactionDisposer? _payjoinDisposer;

  WalletBase? _preLightningWallet;
  ReceivePageOption? _preLightningType;

  WalletBase get wallet => _wallet();
  AmountParsingProxy get _amountParsingProxy => _amountParsingProxyGetter();

  String get walletName => wallet.name;
  WalletType get walletType => wallet.type;
  int? get walletChainId => wallet.chainId;
  String get walletId => wallet.walletInfo.name;
  CryptoCurrency get walletCurrency => wallet.currency;

  List<CryptoCurrency> get receivableTokens =>
      wallet.balance.keys.whereType<CryptoCurrency>().toList();

  bool get hasTokensList => hasTokens(wallet.type);

  bool get infoboxDismissed => wallet.walletInfo.receiveInfoboxDismissed;

  bool get hasAccounts => const {WalletType.monero, WalletType.wownero}.contains(wallet.type);

  bool get hasHiddenAddresses => wallet.walletAddresses.hiddenAddresses.isNotEmpty;

  List<AddressGroup> computeAddressList() {
    final type = wallet.type;

    if (type == WalletType.monero) {
      return [_moneroAddresses()];
    }
    if (type == WalletType.wownero) {
      return [_wowneroAddresses()];
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
    if (type == WalletType.nano || type == WalletType.banano) {
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
    final primary = subaddresses.firstOrNull;
    final entries = subaddresses
        .map(
          (s) => AddressEntry(
            id: s.id,
            address: s.address,
            label: s.label,
            isPrimary: identical(s, primary),
            txCount: s.txCount,
            balance: s.received,
            isHidden: wallet.walletAddresses.hiddenAddresses.contains(s.address),
            isManual: wallet.walletAddresses.manualAddresses.contains(s.address),
          ),
        )
        .toList();
    return AddressGroup(entries: entries);
  }

  AddressGroup _wowneroAddresses() {
    final wallet = this.wallet;
    final subaddresses = wownero!.getSubaddressList(wallet).subaddresses;
    final primary = subaddresses.firstOrNull;
    final entries = subaddresses
        .map(
          (s) => AddressEntry(
            id: s.id,
            address: s.address,
            label: s.label,
            isPrimary: identical(s, primary),
            isHidden: wallet.walletAddresses.hiddenAddresses.contains(s.address),
            isManual: wallet.walletAddresses.manualAddresses.contains(s.address),
          ),
        )
        .toList();
    return AddressGroup(entries: entries);
  }

  List<AddressGroup> _electrumAddresses() {
    final wallet = this.wallet;
    if (bitcoin!.hasSelectedSilentPayments(wallet)) {
      final main = bitcoin!.getSilentPaymentAddresses(wallet).map(_electrumEntry).toList();
      final received = bitcoin!
          .getSilentPaymentReceivedAddresses(wallet)
          .map((a) => _electrumEntry(a, isOneTimeReceiveAddress: true))
          .toList();
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

  AddressEntry _electrumEntry(ElectrumSubAddress addr, {bool isOneTimeReceiveAddress = false}) {
    final wallet = this.wallet;
    final hidden = wallet.walletAddresses.hiddenAddresses.contains(addr.address) ||
        (wallet.type == WalletType.bitcoin && addr.isLegacyDerivation);
    final isPrimary = !isOneTimeReceiveAddress && addr.id == 0;
    return AddressEntry(
      id: addr.id,
      address: addr.address,
      label: addr.name,
      isPrimary: isPrimary,
      isChange: addr.isChange,
      txCount: addr.txCount,
      balance: _amountParsingProxy.getDisplayCryptoString(
        addr.balance,
        walletTypeToCryptoCurrency(wallet.type),
      ),
      isLegacyDerivation: addr.isLegacyDerivation,
      derivationPath: addr.derivationPath,
      isHidden: hidden,
      isManual: wallet.walletAddresses.manualAddresses.contains(addr.address),
      isOneTimeReceiveAddress: isOneTimeReceiveAddress,
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
            isManual: wallet.walletAddresses.manualAddresses.contains(i.address),
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
            isManual: wallet.walletAddresses.manualAddresses.contains(i.address),
          ),
        )
        .toList();
    return AddressGroup(entries: entries);
  }

  List<AddressGroup> _singleAddressGroup(String address) => [
        AddressGroup(entries: [AddressEntry(address: address, isPrimary: true)]),
      ];

  String get currentAddress => wallet.walletAddresses.address;

  Future<void> setActiveAddress(String address) async {
    wallet.walletAddresses.address = address;
  }

  Future<void> rotateAddress() async {
    final wallet = this.wallet;
    final newAddress = await _generateNewAddress("");
    if (newAddress == null || newAddress.isEmpty) {
      return;
    }
    if (!identical(wallet, this.wallet)) {
      return;
    }
    wallet.walletAddresses.address = newAddress;
  }

  Future<void> addManualAddress(String label) => _generateNewAddress(label);

  Future<String?> _generateNewAddress(String label) async {
    final wallet = this.wallet;
    final type = wallet.type;

    if (_isElectrumType(type)) {
      final isSilentPayments = bitcoin!.hasSelectedSilentPayments(wallet);
      final before = isSilentPayments
          ? bitcoin!.getSilentPaymentAddresses(wallet).map((a) => a.address).toSet()
          : bitcoin!.getSubAddresses(wallet).map((a) => a.address).toSet();
      await bitcoin!.generateNewAddress(wallet, label);
      await wallet.save();
      final after = isSilentPayments
          ? bitcoin!.getSilentPaymentAddresses(wallet).toList()
          : bitcoin!.getSubAddresses(wallet).toList();
      if (after.isEmpty) {
        return null;
      }
      final fresh = after.where((a) => !before.contains(a.address)).firstOrNull;
      return (fresh ?? after.last).address;
    }

    if (type == WalletType.decred) {
      final before = decred!.getAddressInfos(wallet).map((a) => a.address).toSet();
      await decred!.generateNewAddress(wallet, label);
      await wallet.save();
      final after = decred!.getAddressInfos(wallet).toList();
      if (after.isEmpty) {
        return null;
      }
      final fresh = after.where((a) => !before.contains(a.address)).firstOrNull;
      return (fresh ?? after.last).address;
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
      if (subs.isEmpty) {
        return null;
      }
      final fresh = subs.where((s) => !beforeIds.contains(s.id)).firstOrNull;
      final newAddress = (fresh ?? subs.reduce((a, b) => a.id > b.id ? a : b)).address;
      wallet.walletAddresses.manualAddresses.add(newAddress);
      await wallet.save();
      return newAddress;
    }

    if (type == WalletType.wownero) {
      final accountIndex = wownero!.getCurrentAccount(wallet).id;
      final beforeIds = wownero!.getSubaddressList(wallet).subaddresses.map((s) => s.id).toSet();
      await wownero!.getSubaddressList(wallet).addSubaddress(
            wallet,
            accountIndex: accountIndex,
            label: label,
          );
      final subAddresses = wownero!.getSubaddressList(wallet).subaddresses;
      if (subAddresses.isEmpty) {
        return null;
      }
      final fresh = subAddresses.where((s) => !beforeIds.contains(s.id)).firstOrNull;
      final newAddress = (fresh ?? subAddresses.reduce((a, b) => a.id > b.id ? a : b)).address;
      wallet.walletAddresses.manualAddresses.add(newAddress);
      await wallet.save();
      return newAddress;
    }

    return null;
  }

  Future<void> setLabel(String address, String label) async {
    final wallet = this.wallet;
    final type = wallet.type;

    if (_isElectrumType(type)) {
      await bitcoin!.updateAddress(wallet, address, label);
      return;
    }

    if (type == WalletType.decred) {
      await decred!.updateAddress(wallet, address, label);
      await wallet.save();
      return;
    }

    final index = _entryIdFor(address);
    if (index == null) {
      return;
    }

    if (type == WalletType.monero) {
      await monero!.getSubaddressList(wallet).setLabelSubaddress(
            wallet,
            accountIndex: monero!.getCurrentAccount(wallet).id,
            addressIndex: index,
            label: label,
          );
      await wallet.save();
      return;
    }

    if (type == WalletType.wownero) {
      await wownero!.getSubaddressList(wallet).setLabelSubaddress(
            wallet,
            accountIndex: wownero!.getCurrentAccount(wallet).id,
            addressIndex: index,
            label: label,
          );
      await wallet.save();
    }
  }

  bool get canSetLabel {
    final type = wallet.type;
    return _isElectrumType(type) ||
        type == WalletType.decred ||
        type == WalletType.monero ||
        type == WalletType.wownero;
  }

  bool get canHide => wallet.type != WalletType.zcash;

  int? _entryIdFor(String address) {
    for (final group in computeAddressList()) {
      for (final entry in group.entries) {
        if (entry.address == address) {
          return entry.id;
        }
      }
    }
    return null;
  }

  Future<void> setHidden(String address, {required bool hidden}) async {
    final wallet = this.wallet;
    if (hidden) {
      wallet.walletAddresses.hiddenAddresses.add(address);
    } else {
      wallet.walletAddresses.hiddenAddresses.removeWhere((e) => e == address);
    }

    await wallet.walletAddresses.saveAddressesInBox();

    final type = wallet.type;
    if (type == WalletType.monero) {
      await monero!.getSubaddressList(wallet).update(
            wallet,
            accountIndex: monero!.getCurrentAccount(wallet).id,
          );
      return;
    }
    if (type == WalletType.wownero) {
      wownero!.getSubaddressList(wallet).update(
            wallet,
            accountIndex: wownero!.getCurrentAccount(wallet).id,
          );
    }
  }

  Future<void> deleteSilentPaymentAddress(String address) async {
    final wallet = this.wallet;
    if (wallet.type != WalletType.bitcoin) {
      return;
    }
    final wasActive = wallet.walletAddresses.address == address;
    bitcoin!.deleteSilentPaymentAddress(wallet, address);
    if (wasActive) {
      final mains = bitcoin!.getSilentPaymentAddresses(wallet).toList();
      if (mains.isNotEmpty) {
        wallet.walletAddresses.address = mains.first.address;
      } else {
        await applyOpenDefaults(lightningMode: false);
      }
    }
    await wallet.save();
  }

  ReceivePageOption? get selectedAddressType {
    final type = wallet.type;
    if (type == WalletType.bitcoin || type == WalletType.litecoin) {
      return bitcoin!.getSelectedAddressType(wallet);
    }
    if (type == WalletType.zcash) {
      return zcash!.getSelectedAddressType(wallet);
    }
    return null;
  }

  List<ReceivePageOption> get addressTypeOptions => wallet.walletAddresses.receivePageOptions;

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

  PaymentURI buildPaymentUri({required String rawAmount, CryptoCurrency? token}) {
    final type = wallet.type;
    final address = wallet.walletAddresses.address;

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

  Future<PaymentURI> fetchPaymentRequestUri({
    required String rawAmount,
    CryptoCurrency? token,
  }) async {
    if (token is Erc20Token || token is TronToken || token is SPLToken) {
      return buildPaymentUri(rawAmount: rawAmount, token: token);
    }
    return wallet.walletAddresses.getPaymentRequestUri(rawAmount);
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

  String? _emptyToNull(String v) => v.isEmpty ? null : v;

  Future<void> dispose() async {
    _payjoinDisposer?.call();
    _payjoinDisposer = null;
    await _walletSub.cancel();
    await _payjoinController.close();
  }

  AddressAccount? get currentAccount {
    final type = wallet.type;
    if (type == WalletType.monero) {
      final acc = monero!.getCurrentAccount(wallet);
      return AddressAccount(id: acc.id, label: acc.label);
    }
    if (type == WalletType.wownero) {
      final acc = wownero!.getCurrentAccount(wallet);
      return AddressAccount(id: acc.id, label: acc.label);
    }
    return null;
  }

  bool get isBalanceAvailable => _isElectrumType(wallet.type);

  bool get isReceivedAvailable =>
      const {WalletType.monero, WalletType.wownero}.contains(wallet.type);

  bool get isBitcoinViewOnly {
    if (wallet.type != WalletType.bitcoin) {
      return false;
    }
    return (bitcoin!.getWalletKeys(wallet)["privateKey"] ?? "").isEmpty;
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

    if (bitcoin!.hasSelectedSilentPayments(wallet) &&
        bitcoin!.getSilentPaymentAddresses(wallet).isEmpty) {
      await _setAddressTypeOn(wallet, bitcoin!.getBitcoinSegwitPageOption());
      if (bitcoin!.getSubAddresses(wallet).isEmpty) {
        await bitcoin!.generateNewAddress(wallet, "");
        await wallet.save();
      }
      return;
    }

    final current = bitcoin!.getSelectedAddressType(wallet);
    final lightning = bitcoin!.getBitcoinLightningReceivePageOption();

    if (lightningMode) {
      if (current == lightning) {
        return;
      }
      _preLightningWallet = wallet;
      _preLightningType = current;
      await _setAddressTypeOn(wallet, lightning);
      return;
    }

    if (current == lightning) {
      final previous = identical(_preLightningWallet, wallet) ? _preLightningType : null;
      _preLightningWallet = null;
      _preLightningType = null;
      await _setAddressTypeOn(wallet, previous ?? bitcoin!.getBitcoinSegwitPageOption());
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

  Future<void> dismissInfobox() async {
    wallet.walletInfo.receiveInfoboxDismissed = true;
    try {
      await wallet.walletInfo.save();
    } catch (e) {
      printV("failed to save receiveInfoboxDismissed: $e");
    }
  }

  bool useSatoshi(Currency currency) => _amountParsingProxy.useSatoshi(currency);

  String canonicalCryptoAmount(String raw, CryptoCurrency currency) =>
      _amountParsingProxy.getCanonicalCryptoAmount(raw, currency);

  String get accountLabel => currentAccount?.label ?? "";

  bool _isElectrumType(WalletType type) =>
      type == WalletType.bitcoin ||
      type == WalletType.litecoin ||
      type == WalletType.bitcoinCash ||
      type == WalletType.dogecoin;
}
