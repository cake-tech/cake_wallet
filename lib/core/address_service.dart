import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/core/amount_parsing_proxy.dart";
import "package:cake_wallet/decred/decred.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/zano/zano.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/spl_token.dart";
import "package:cw_core/tron_token.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";

class AddressService {
  AddressService({
    required WalletBase Function() wallet,
    required SettingsStore settingsStore,
    required AmountParsingProxy Function() amountParsingProxyGetter,
  })  : _wallet = wallet,
        _settingsStore = settingsStore,
        _amountParsingProxyGetter = amountParsingProxyGetter;

  final WalletBase Function() _wallet;
  final SettingsStore _settingsStore;
  final AmountParsingProxy Function() _amountParsingProxyGetter;

  WalletBase get wallet => _wallet();
  AmountParsingProxy get _amountParsingProxy => _amountParsingProxyGetter();

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

  Future<List<AddressGroup>> fetchAddressList() async => computeAddressList();

  AddressGroup _moneroAddresses() {
    final w = wallet;
    final subaddresses = monero!.getSubaddressList(w).subaddresses;
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
            isHidden: w.walletAddresses.hiddenAddresses.contains(s.address),
            isManual: w.walletAddresses.manualAddresses.contains(s.address),
          ),
        )
        .toList();
    return AddressGroup(entries: entries);
  }

  List<AddressGroup> _electrumAddresses() {
    final w = wallet;
    if (bitcoin!.hasSelectedSilentPayments(w)) {
      final main = bitcoin!.getSilentPaymentAddresses(w).map(_electrumEntry).toList();
      final received = bitcoin!
          .getSilentPaymentReceivedAddresses(w)
          .map((a) => _electrumEntry(a, isOneTimeReceiveAddress: true))
          .toList();
      return [
        AddressGroup(entries: main),
        AddressGroup(header: const SilentPaymentsReceivedHeader(), entries: received),
      ];
    }

    var entries = bitcoin!.getSubAddresses(w).map(_electrumEntry).toList();

    // mweb can generate 1000+ derived addresses, we show up to the last
    // one with a tx count, plus 20 more
    if (w.type == WalletType.litecoin && entries.length >= 1000) {
      var index = entries.lastIndexWhere((e) => (e.txCount ?? 0) > 0);
      if (index == -1) {
        index = 0;
      }
      entries = entries.sublist(0, index + 20);
    }

    return [AddressGroup(entries: entries)];
  }

  AddressEntry _electrumEntry(ElectrumSubAddress addr, {bool isOneTimeReceiveAddress = false}) {
    final w = wallet;
    final hidden =
        w.walletAddresses.hiddenAddresses.contains(addr.address) || addr.isLegacyDerivation;
    return AddressEntry(
      id: addr.id,
      address: addr.address,
      label: addr.name,
      isPrimary: addr.id == 0,
      isChange: addr.isChange,
      txCount: addr.txCount,
      balance: _amountParsingProxy.getDisplayCryptoString(
        addr.balance,
        walletTypeToCryptoCurrency(w.type),
      ),
      isLegacyDerivation: addr.isLegacyDerivation,
      derivationPath: addr.derivationPath,
      isHidden: hidden,
      isManual: w.walletAddresses.manualAddresses.contains(addr.address),
      isOneTimeReceiveAddress: isOneTimeReceiveAddress,
    );
  }

  AddressGroup _decredAddresses() {
    final w = wallet;
    final entries = decred!
        .getAddressInfos(w)
        .map(
          (i) => AddressEntry(
            address: i.address,
            label: i.label,
            isHidden: w.walletAddresses.hiddenAddresses.contains(i.address),
            isManual: w.walletAddresses.manualAddresses.contains(i.address),
          ),
        )
        .toList();
    return AddressGroup(entries: entries);
  }

  AddressGroup _zcashAddresses() {
    final w = wallet;
    final entries = zcash!
        .getAddressInfos(w)
        .map(
          (i) => AddressEntry(
            address: i.address,
            label: i.label,
            isHidden: w.walletAddresses.hiddenAddresses.contains(i.address),
            isManual: w.walletAddresses.manualAddresses.contains(i.address),
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
    await _generateNewAddress("");
    final entries = computeAddressList().expand((g) => g.entries).toList();
    if (entries.isNotEmpty) {
      wallet.walletAddresses.address = entries.last.address;
    }
  }

  Future<void> addManualAddress(String label) => _generateNewAddress(label);

  Future<void> _generateNewAddress(String label) async {
    final type = wallet.type;

    if (_isElectrumType(type)) {
      await bitcoin!.generateNewAddress(wallet, label);
      await wallet.save();
      return;
    }

    if (type == WalletType.decred) {
      await decred!.generateNewAddress(wallet, label);
      await wallet.save();
      return;
    }

    if (type == WalletType.monero) {
      await monero!.getSubaddressList(wallet).addSubaddress(
            wallet,
            accountIndex: monero!.getCurrentAccount(wallet).id,
            label: label,
          );
      final subaddresses = monero!.getSubaddressList(wallet).subaddresses;
      if (subaddresses.isEmpty) {
        return;
      }
      wallet.walletAddresses.manualAddresses.add(subaddresses.first.address);
      await wallet.save();
      return;
    }
  }

  Future<void> setLabel(String address, String label) async {
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
  }

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
    if (hidden) {
      wallet.walletAddresses.hiddenAddresses.add(address);
    } else {
      wallet.walletAddresses.hiddenAddresses.removeWhere((e) => e == address);
    }

    await wallet.walletAddresses.saveAddressesInBox();

    if (wallet.type == WalletType.monero) {
      await monero!
          .getSubaddressList(wallet)
          .update(wallet, accountIndex: monero!.getCurrentAccount(wallet).id);
    }
  }

  Future<void> deleteSilentPaymentAddress(String address) async {
    if (wallet.type != WalletType.bitcoin) {
      return;
    }
    bitcoin!.deleteSilentPaymentAddress(wallet, address);
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

  Future<void> setAddressType(ReceivePageOption option) async {
    final type = wallet.type;
    if (type == WalletType.bitcoin || type == WalletType.litecoin) {
      await bitcoin!.setAddressType(wallet, bitcoin!.getOptionToType(option));
      return;
    }
    if (type == WalletType.zcash) {
      await zcash!.setAddressType(wallet, zcash!.getZcashAddressType(option));
    }
  }

  Future<void> setAddressTypeRaw(dynamic chainSpecificType) async {
    final type = wallet.type;
    if (type == WalletType.bitcoin || type == WalletType.litecoin) {
      await bitcoin!.setAddressType(wallet, chainSpecificType);
      return;
    }
    if (type == WalletType.zcash) {
      await zcash!.setAddressType(wallet, chainSpecificType);
    }
  }

  PaymentURI buildPaymentUri({required String rawAmount, CryptoCurrency? token}) {
    final type = wallet.type;
    final address = wallet.walletAddresses.address;

    if (token != null && isEVMCompatibleChain(type)) {
      return ERC681URI(
        chainId: wallet.chainId ?? 1,
        address: address,
        amount: rawAmount,
        contractAddress: (token as Erc20Token).contractAddress,
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
    if (token != null && isEVMCompatibleChain(wallet.type)) {
      return buildPaymentUri(rawAmount: rawAmount, token: token);
    }
    return wallet.walletAddresses.getPaymentRequestUri(rawAmount);
  }

  String get payjoinEndpoint =>
      wallet.type == WalletType.bitcoin ? bitcoin!.getPayjoinEndpoint(wallet) : "";

  bool get isPayjoinUnavailable => payjoinEndpoint.isEmpty;

  AddressAccount? get currentAccount {
    final type = wallet.type;
    if (type == WalletType.monero) {
      final acc = monero!.getCurrentAccount(wallet);
      return AddressAccount(id: acc.id, label: acc.label);
    }
    return null;
  }

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

  bool _isElectrumType(WalletType type) =>
      type == WalletType.bitcoin ||
      type == WalletType.litecoin ||
      type == WalletType.bitcoinCash ||
      type == WalletType.dogecoin;
}
