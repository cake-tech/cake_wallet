import 'dart:async' show Zone;
import 'dart:io' show Platform;
import 'dart:math';
import "package:collection/collection.dart";

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import "package:cw_bitcoin/bitcoin_receive_page_option.dart";
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/lightning/lightning_addres_type.dart';
import 'package:cw_bitcoin/lightning/lightning_wallet.dart';
import "package:cw_core/address_entry.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import "package:cw_core/receive_page_option.dart";
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/generate_name.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'electrum_wallet_addresses.g.dart';

class UnsupportedAddressTypeForAccountException implements Exception {
  UnsupportedAddressTypeForAccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class ElectrumWalletAddresses = ElectrumWalletAddressesBase with _$ElectrumWalletAddresses;

const List<BitcoinAddressType> BITCOIN_ADDRESS_TYPES = [
  SegwitAddresType.p2wpkh,
  P2pkhAddressType.p2pkh,
  SegwitAddresType.p2tr,
  SegwitAddresType.p2wsh,
  P2shAddressType.p2wpkhInP2sh,
];

const List<BitcoinAddressType> LEGACY_DUPLICATE_ADDRESS_TYPES = [
  SegwitAddresType.p2wpkh,
  SegwitAddresType.p2wsh,
];

const List<BitcoinAddressType> LITECOIN_ADDRESS_TYPES = [
  SegwitAddresType.p2wpkh,
  SegwitAddresType.mweb,
];

const List<BitcoinAddressType> BITCOIN_CASH_ADDRESS_TYPES = [
  P2pkhAddressType.p2pkh,
];

const List<BitcoinAddressType> DOGECOIN_ADDRESS_TYPES = [
  P2pkhAddressType.p2pkh,
];

const List<BitcoinAddressType> EXTRA_ACCOUNT_ADDRESS_TYPES = [SegwitAddresType.p2wpkh];

abstract class ElectrumWalletAddressesBase extends WalletAddresses with Store {
  ElectrumWalletAddressesBase(
    WalletInfo walletInfo, {
    required this.mainHdByTypeAndAccount,
    required this.sideHdByTypeAndAccount,
    required this.accountIndexes,
    required this.currentAccountIndex,
    required this.legacyMainHd,
    required this.legacySideHd,
    required this.network,
    required this.isHardwareWallet,
    List<BitcoinAddressRecord>? initialAddresses,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    int initialSilentAddressIndex = 0,
    List<BitcoinAddressRecord>? initialMwebAddresses,
    Bip32Slip10Secp256k1? masterHd,
    BitcoinAddressType? initialAddressPageType,
    this.lightningWallet,
  })  : _addresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? []).toSet()),
        addressesByReceiveType =
            ObservableList<BaseBitcoinAddressRecord>.of((<BitcoinAddressRecord>[]).toSet()),
        receiveAddresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? [])
            .where((addressRecord) => !addressRecord.isHidden && !addressRecord.isUsed)
            .toSet()),
        changeAddresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? [])
            .where((addressRecord) => addressRecord.isHidden && !addressRecord.isUsed)
            .toSet()),
        currentReceiveAddressIndexByType = initialRegularAddressIndex ?? {},
        currentChangeAddressIndexByType = initialChangeAddressIndex ?? {},
        _addressPageType = _resolveInitialAddressPageType(
          initialAddressPageType: initialAddressPageType,
          walletInfo: walletInfo,
          mainHdByTypeAndAccount: mainHdByTypeAndAccount,
          currentAccountIndex: currentAccountIndex,
        ),
        silentAddresses = ObservableList<BitcoinSilentPaymentAddressRecord>.of(
            (initialSilentAddresses ?? []).toSet()),
        currentSilentAddressIndex = initialSilentAddressIndex,
        mwebAddresses =
            ObservableList<BitcoinAddressRecord>.of((initialMwebAddresses ?? []).toSet()),
        lockedReceiveAddressByType = ObservableMap<BitcoinAddressType, String>(),
        previousAddressRecordByType = ObservableMap<BitcoinAddressType, BitcoinAddressRecord>(),
        lightningAddress = lightningWallet?.cachedAddress,
        super(walletInfo) {
    if (_addressPageType is LightningAddressType ||
        _addressPageType == SilentPaymentsAddresType.p2sp) {
      _addressPageType = SegwitAddresType.p2wpkh;
    }

    if (masterHd != null) {
      silentAddress = SilentPaymentOwner.fromPrivateKeys(
        b_scan:
            ECPrivate.fromHex(masterHd.derivePath(SILENT_PAYMENTS_SCAN_PATH).privateKey.toHex()),
        b_spend:
            ECPrivate.fromHex(masterHd.derivePath(SILENT_PAYMENTS_SPEND_PATH).privateKey.toHex()),
        network: network,
      );

      // Clean the Silent Payment Addresses if the initial addresses are the old SP Addresses
      if (!silentAddresses
          .any((addr) => addr.index == 0 && addr.address == silentAddress.toString())) {
        silentAddresses.clear();
      }

      if (!silentAddresses.any((addr) => addr.index == 0 && addr.isHidden == false))
        silentAddresses.add(BitcoinSilentPaymentAddressRecord(
          silentAddress.toString(),
          index: 0,
          isHidden: false,
          name: "",
          silentPaymentTweak: null,
          network: network,
          type: SilentPaymentsAddresType.p2sp,
        ));
      for (var i = 0; i < 5; i++) {
        if (!silentAddresses.any((addr) => addr.index == i && addr.isHidden == (i == 0)))
          silentAddresses.add(BitcoinSilentPaymentAddressRecord(
            silentAddress!.toLabeledSilentPaymentAddress(i).toString(),
            index: i,
            isHidden: i == 0,
            name: "",
            silentPaymentTweak: BytesUtils.toHexString(silentAddress!.generateLabel(i)),
            network: network,
            type: SilentPaymentsAddresType.p2sp,
          ));
      }
    }
    updateAddressesByMatch();
  }

  static const defaultReceiveAddressesCount = 22;
  static const defaultChangeAddressesCount = 17;
  static const gap = 20;

  final ObservableList<BitcoinAddressRecord> _addresses;
  final ObservableList<BaseBitcoinAddressRecord> addressesByReceiveType;
  final ObservableList<BitcoinAddressRecord> receiveAddresses;
  final ObservableList<BitcoinAddressRecord> changeAddresses;

  // TODO: add this variable in `bitcoin_wallet_addresses` and just add a cast in cw_bitcoin to use it
  final ObservableList<BitcoinSilentPaymentAddressRecord> silentAddresses;

  // TODO: add this variable in `litecoin_wallet_addresses` and just add a cast in cw_bitcoin to use it
  final ObservableList<BitcoinAddressRecord> mwebAddresses;
  final BasedUtxoNetwork network;
  final Map<int, Map<BitcoinAddressType, Bip32Slip10Secp256k1>> mainHdByTypeAndAccount;
  final Map<int, Map<BitcoinAddressType, Bip32Slip10Secp256k1>> sideHdByTypeAndAccount;
  List<int> accountIndexes;

  @override
  @observable
  int currentAccountIndex;
  final Bip32Slip10Secp256k1 legacyMainHd;
  final Bip32Slip10Secp256k1 legacySideHd;
  final bool isHardwareWallet;
  LightningWallet? lightningWallet;

  @observable
  ObservableMap<BitcoinAddressType, String> lockedReceiveAddressByType;

  @observable
  SilentPaymentOwner? silentAddress;

  @observable
  late BitcoinAddressType _addressPageType;

  @computed
  BitcoinAddressType get addressPageType => _addressPageType;

  @observable
  String? activeSilentAddress;

  @observable
  String? lightningAddress;

  @computed
  List<BitcoinAddressRecord> get allAddresses => _addresses;

  @observable
  bool addressRefreshToggle = false;

  @action
  String getFreshAddress() {
    addressRefreshToggle = !addressRefreshToggle;
    return address;
  }

  @override
  String get addressForExchange => getFreshAddress();

  @override
  @computed
  String get address => _addressOfType(addressPageType);

  @override
  ReceivePageOption get defaultAddressType {
    final option = BitcoinReceivePageOption.fromType(addressPageType);
    return receivePageOptions.contains(option) ? option : super.defaultAddressType;
  }

  @override
  String addressFor(ReceivePageOption type) => _addressOfType(typeFor(type));

  BitcoinAddressType typeFor(ReceivePageOption option) =>
      option is BitcoinReceivePageOption ? option.toType() : addressPageType;

  @override
  bool autoGeneratesAddresses(ReceivePageOption type) =>
      typeFor(type) != SilentPaymentsAddresType.p2sp;

  @override
  Future<String?> loadAccountLabel() async {
    final accounts = await walletInfo.getAccounts();
    return accounts
        .firstWhereOrNull((account) => account.accountIndex == currentAccountIndex)
        ?.label;
  }

  @override
  List<AddressGroup> addressListFor(ReceivePageOption option) {
    final type = typeFor(option);
    if (type is LightningAddressType) {
      return const [];
    }

    if (type == SilentPaymentsAddresType.p2sp) {
      return [
        AddressGroup(
          entries: silentAddresses
              .where((addr) => addr.type != SegwitAddresType.p2tr)
              .map(_addressEntryFor)
              .toList(),
        ),
        AddressGroup(
          header: const SilentPaymentsReceivedHeader(),
          entries: silentAddresses
              .where((addr) => addr.type == SegwitAddresType.p2tr)
              .map(_addressEntryFor)
              .toList(),
        ),
      ];
    }

    List<AddressEntry> entries = _addresses
        .where((addr) => _isCurrentAccountAddress(addr) && _isAddressByType(addr, type))
        .map(_addressEntryFor)
        .toList();

    if (walletInfo.type == WalletType.litecoin && entries.length >= _mwebTruncationThreshold) {
      int index = entries.lastIndexWhere((e) => (e.txCount ?? 0) > 0);
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

  AddressEntry _addressEntryFor(BaseBitcoinAddressRecord addr) => AddressEntry(
        id: addr.index,
        address: addr.address,
        label: addr.name,
        txCount: addr.txCount,
        balance: Money.fromInt(addr.balance, walletTypeToCryptoCurrency(walletInfo.type)),
        derivationPath: addr.derivationPath,
        isHidden: hiddenAddresses.contains(addr.address) ||
            (walletInfo.type == WalletType.bitcoin && addr.isLegacyDerivation),
      );

  String _addressOfType(BitcoinAddressType type) {
    final _ = addressRefreshToggle;
    if (type == SilentPaymentsAddresType.p2sp) {
      if (activeSilentAddress != null) {
        return activeSilentAddress!;
      }

      return silentAddress.toString();
    }

    if (type == LightningAddressType.p2l) {
      return lightningAddress ??
          "Error: Unable to fetch your Lightning address, please check your network connection.";
    }

    final accountIndexForCheck = walletInfo.type == WalletType.bitcoin ? currentAccountIndex : 0;
    if (!_isAddressTypeSupportedForAccount(type, accountIndexForCheck)) {
      printV("address type $type is not supported for account $accountIndexForCheck");
      return "";
    }

    final typeMatchingAddressesAll = _addresses
        .where((addr) =>
            _isCurrentAccountAddress(addr) && !addr.isHidden && _isAddressByType(addr, type))
        .toList();

    // Prefer standard derivation addresses for the current/active address,
    // but keep legacy addresses present in the overall address lists.
    final typeMatchingAddresses = <BitcoinAddressRecord>[
      ...typeMatchingAddressesAll.where((a) => !a.isLegacyDerivation),
      ...typeMatchingAddressesAll.where((a) => a.isLegacyDerivation),
    ];

    final typeMatchingReceiveAddressesAll = typeMatchingAddressesAll
        .where((addr) => !addr.isUsed && !hiddenAddresses.contains(addr.address))
        .toList();
    final typeMatchingReceiveAddresses = <BitcoinAddressRecord>[
      ...typeMatchingReceiveAddressesAll.where((a) => !a.isLegacyDerivation),
      ...typeMatchingReceiveAddressesAll.where((a) => a.isLegacyDerivation),
    ];

    final previousRecord = previousAddressRecordByType[type];
    final prev =
        previousRecord != null && _isCurrentAccountAddress(previousRecord) ? previousRecord : null;
    if (!isEnabledAutoGenerateSubaddress) {
      if (prev != null) {
        return prev.address;
      }

      if (typeMatchingAddresses.isNotEmpty) {
        return typeMatchingAddresses.first.address;
      }

      return generateNewAddress(type: type).address;
    }

    if (typeMatchingAddresses.isEmpty || typeMatchingReceiveAddresses.isEmpty) {
      return generateNewAddress(type: type).address;
    }

    final locked = lockedReceiveAddressByType[type];
    if (locked != null && !hiddenAddresses.contains(locked)) return locked;

    if (prev != null &&
        !prev.isUsed &&
        !prev.isLegacyDerivation &&
        !hiddenAddresses.contains(prev.address)) {
      return prev.address;
    }

    return typeMatchingReceiveAddresses.first.address;
  }

  @observable
  bool isEnabledAutoGenerateSubaddress = true;

  @override
  set address(String addr) {
    if (addr == "Silent Payments" && SilentPaymentsAddresType.p2sp != addressPageType) {
      return;
    }
    final selected = silentAddresses.where((record) => record.address == addr).firstOrNull;
    if (selected != null) {
      if (selected.silentPaymentTweak != null && silentAddress != null) {
        activeSilentAddress =
            silentAddress!.toLabeledSilentPaymentAddress(selected.index).toString();
      } else {
        activeSilentAddress = silentAddress!.toString();
      }
      return;
    }
    try {
      final addressRecord = _addresses.firstWhere(
        (addressRecord) => addressRecord.address == addr && !addressRecord.isLegacyDerivation,
        orElse: () => _addresses.firstWhere((r) => r.address == addr),
      );

      lockedReceiveAddressByType.remove(addressRecord.type);

      previousAddressRecordByType[addressRecord.type] = addressRecord;
      receiveAddresses.remove(addressRecord);
      receiveAddresses.insert(0, addressRecord);

      if (isEnabledAutoGenerateSubaddress && addressRecord.isUsed) {
        lockedReceiveAddressByType[addressRecord.type] = addr;
      }
    } catch (e) {
      printV("ElectrumWalletAddressBase: set address ($addr): $e");
    }
  }

  @action
  void clearLockIfMatches(BitcoinAddressType type, String address) {
    final locked = lockedReceiveAddressByType[type];
    if (locked != null && locked == address) {
      lockedReceiveAddressByType.remove(type);
    }
  }

  @override
  String get primaryAddress {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      return silentAddress?.toString() ?? '';
    }

    return _firstAddressForType(addressPageType);
  }

  String get payjoinCompatibleAddress {
    final addrType = (addressPageType == SilentPaymentsAddresType.p2sp ||
            addressPageType == LightningAddressType.p2l)
        ? SegwitAddresType.p2wpkh
        : addressPageType;

    return _firstAddressForType(addrType);
  }

  String _firstAddressForType(BitcoinAddressType addrType) {
    final mainMap = walletInfo.type == WalletType.bitcoin
        ? mainHdByTypeAndAccount[currentAccountIndex]
        : mainHdByTypeAndAccount[0];

    final mainHd = mainMap?[addrType] ?? mainMap?.values.first;

    if (mainHd == null) return '';

    return getAddress(index: 0, hd: mainHd, addressType: addrType);
  }

  Map<String, int> currentReceiveAddressIndexByType;

  int get currentReceiveAddressIndex =>
      currentReceiveAddressIndexByType[_addressPageType.toString()] ?? 0;

  void set currentReceiveAddressIndex(int index) =>
      currentReceiveAddressIndexByType[_addressPageType.toString()] = index;

  Map<String, int> currentChangeAddressIndexByType;

  int get currentChangeAddressIndex =>
      currentChangeAddressIndexByType[_addressPageType.toString()] ?? 0;

  void set currentChangeAddressIndex(int index) =>
      currentChangeAddressIndexByType[_addressPageType.toString()] = index;

  int currentSilentAddressIndex;

  @observable
  ObservableMap<BitcoinAddressType, BitcoinAddressRecord> previousAddressRecordByType;

  @computed
  int get totalCountOfReceiveAddresses => addressesByReceiveType.fold(0, (acc, addressRecord) {
        if (!addressRecord.isHidden) {
          return acc + 1;
        }
        return acc;
      });

  @computed
  int get totalCountOfChangeAddresses => addressesByReceiveType.fold(0, (acc, addressRecord) {
        if (addressRecord.isHidden) {
          return acc + 1;
        }
        return acc;
      });

  @override
  Future<void> init({List<int> accountIndexes = const []}) async {
    final effectiveAccountIndexes =
        accountIndexes.isNotEmpty ? accountIndexes : this.accountIndexes;

    if (accountIndexes.isNotEmpty) this.accountIndexes = accountIndexes;
    if (walletInfo.type == WalletType.bitcoinCash) {
      await _generateInitialAddresses(type: P2pkhAddressType.p2pkh);
    } else if (walletInfo.type == WalletType.litecoin) {
      await _generateInitialAddresses(type: SegwitAddresType.p2wpkh);
      if ((Platform.isAndroid || Platform.isIOS) && !isHardwareWallet) {
        await _generateInitialAddresses(type: SegwitAddresType.mweb);
      }
    } else if (walletInfo.type == WalletType.dogecoin) {
      await _generateInitialAddresses(type: P2pkhAddressType.p2pkh);
    } else if (walletInfo.type == WalletType.bitcoin) {
      for (final accountIndex in effectiveAccountIndexes) {

        await prepareAccountAddresses(
          accountIndex,
          types: accountIndex == 0 ? BITCOIN_ADDRESS_TYPES : EXTRA_ACCOUNT_ADDRESS_TYPES,
          includeLegacy: accountIndex == 0,
        );
      }
    }

    updateAddressesByMatch();
    updateReceiveAddresses();
    updateChangeAddresses();
    await _validateAddresses();
    await updateAddressesInBox();

    if (currentReceiveAddressIndex >= receiveAddresses.length) {
      currentReceiveAddressIndex = 0;
    }

    if (currentChangeAddressIndex >= changeAddresses.length) {
      currentChangeAddressIndex = 0;
    }
  }

  @action
  Future<BitcoinAddressRecord> getChangeAddress(
      {List<BitcoinUnspent>? inputs,
      List<BitcoinOutput>? outputs,
      UnspentCoinType coinTypeToSpendFrom = UnspentCoinType.any}) async {
    updateChangeAddresses();

    if (changeAddresses.isEmpty) {
      final accountChangeCount = _addresses
          .where((addressRecord) =>
              _isCurrentAccountAddress(addressRecord) &&
              addressRecord.isHidden &&
              addressRecord.type == addressPageType)
          .length;

      final newAddresses = await _createNewAddresses(
        gap,
        startIndex: accountChangeCount,
        isHidden: true,
        type: addressPageType,
        accountIndex: currentAccountIndex,
      );

      addAddresses(newAddresses);
    }

    if (currentChangeAddressIndex >= changeAddresses.length) {
      currentChangeAddressIndex = 0;
    }

    updateChangeAddresses();
    final address = changeAddresses[currentChangeAddressIndex];
    currentChangeAddressIndex += 1;
    return address;
  }

  bool _isCurrentAccountAddress(BitcoinAddressRecord addressRecord) {
    return walletInfo.type != WalletType.bitcoin ||
        addressRecord.accountIndex == currentAccountIndex;
  }

  Map<String, String> get labels {
    final G = ECPublic.fromBytes(BigintUtils.toBytes(Curves.generatorSecp256k1.x, length: 32));
    final labels = <String, String>{};
    for (int i = 0; i < silentAddresses.length; i++) {
      final silentAddressRecord = silentAddresses[i];
      final silentPaymentTweak = silentAddressRecord.silentPaymentTweak;

      if (silentPaymentTweak != null &&
          SilentPaymentAddress.regex.hasMatch(silentAddressRecord.address)) {
        labels[G
            .tweakMul(BigintUtils.fromBytes(BytesUtils.fromHexString(silentPaymentTweak)))
            .toHex()] = silentPaymentTweak;
      }
    }
    return labels;
  }

  Future<void> prepareAccountAddresses(
    int accountIndex, {
    List<BitcoinAddressType> types = BITCOIN_ADDRESS_TYPES,
    bool includeLegacy = false,
  }) async {
    for (final type in types) {
      final shouldSkipHardwareWalletType = isHardwareWallet && type != SegwitAddresType.p2wpkh;

      if (shouldSkipHardwareWalletType) continue;

      await _generateInitialAddresses(accountIndex: accountIndex, type: type);

      // Legacy derivation for these types is identical to the standard one.
      if (includeLegacy && !LEGACY_DUPLICATE_ADDRESS_TYPES.contains(type)) {
        await _generateInitialAddresses(
          accountIndex: accountIndex,
          type: type,
          isLegacyDerivation: true,
        );
      }
    }
  }

  @action
  BaseBitcoinAddressRecord generateNewAddress({String label = "", BitcoinAddressType? type}) {
    final addressType = type ?? addressPageType;
    if (addressType is LightningAddressType) {
      throw Exception("Lightning addresses cannot be rotated");
    }

    if (addressType == SilentPaymentsAddresType.p2sp && silentAddress != null) {
      final currentSilentAddressIndex = silentAddresses
              .where((addressRecord) => addressRecord.type != SegwitAddresType.p2tr)
              .length -
          1;

      this.currentSilentAddressIndex = currentSilentAddressIndex;

      final address = BitcoinSilentPaymentAddressRecord(
        silentAddress!.toLabeledSilentPaymentAddress(currentSilentAddressIndex).toString(),
        index: currentSilentAddressIndex,
        isHidden: false,
        name: label,
        silentPaymentTweak:
            BytesUtils.toHexString(silentAddress!.generateLabel(currentSilentAddressIndex)),
        network: network,
        type: SilentPaymentsAddresType.p2sp,
      );

      silentAddresses.add(address);
      Future.delayed(Duration.zero, () => updateAddressesByMatch());

      return address;
    }

    final accountIndex = walletInfo.type == WalletType.bitcoin ? currentAccountIndex : 0;

    final newAddressIndex = _addresses
        .where((addr) =>
            addr.accountIndex == accountIndex &&
            _isAddressByType(addr, addressType) &&
            !addr.isHidden)
        .length;

    final hd = _hdForAddressGeneration(
      isHidden: false,
      type: addressType,
      isLegacyDerivation: false,
      accountIndex: accountIndex,
    );
    final address = BitcoinAddressRecord(
      getAddress(index: newAddressIndex, hd: hd, addressType: addressType),
      index: newAddressIndex,
      accountIndex: accountIndex,
      isHidden: false,
      isHiddenChecked: true,
      isLegacyDerivation: false,
      name: label,
      type: addressType,
      network: network,
    );
    Future.delayed(Duration.zero, () {
      if (!_addresses.contains(address)) {
        _addresses.add(address);
      }
      updateAddressesByMatch();
    });
    return address;
  }

  String getAddress({
    required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType,
  }) =>
      '';

  Future<String> getAddressAsync({
    required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType,
  }) async =>
      getAddress(index: index, hd: hd, addressType: addressType);

  void addBitcoinAddressTypes() {
    final lastP2wpkh = _addresses
        .where((addressRecord) =>
        _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2wpkh))
        .lastOrNull;
    if (lastP2wpkh != null) {
      if (lastP2wpkh.address != address) {
        addressesMap[lastP2wpkh.address] = 'P2WPKH';
      } else {
        addressesMap[address] = 'Active - P2WPKH';
      }
    }

    final lastP2pkh = _addresses.firstWhereOrNull(
            (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, P2pkhAddressType.p2pkh));
    if (lastP2pkh != null) {
      if (lastP2pkh.address != address) {
        addressesMap[lastP2pkh.address] = 'P2PKH';
      } else {
        addressesMap[address] = 'Active - P2PKH';
      }
    }

    final lastP2sh = _addresses.firstWhereOrNull((addressRecord) =>
        _isUnusedReceiveAddressByType(addressRecord, P2shAddressType.p2wpkhInP2sh));
    if (lastP2sh != null) {
      if (lastP2sh.address != address) {
        addressesMap[lastP2sh.address] = 'P2SH';
      } else {
        addressesMap[address] = 'Active - P2SH';
      }
    }

    final lastP2tr = _addresses.firstWhereOrNull(
            (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2tr));
    if (lastP2tr != null) {
      if (lastP2tr.address != address) {
        addressesMap[lastP2tr.address] = 'P2TR';
      } else {
        addressesMap[address] = 'Active - P2TR';
      }
    }

    final lastP2wsh = _addresses.firstWhereOrNull(
            (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2wsh));
    if (lastP2wsh != null) {
      if (lastP2wsh.address != address) {
        addressesMap[lastP2wsh.address] = 'P2WSH';
      } else {
        addressesMap[address] = 'Active - P2WSH';
      }
    }

    final firstSilentAddressRecord = silentAddresses.firstOrNull;
    if (firstSilentAddressRecord != null) {
      if (firstSilentAddressRecord.address != address) {
        addressesMap[firstSilentAddressRecord.address] = firstSilentAddressRecord.name.isEmpty
            ? "Silent Payments"
            : "Silent Payments - ${firstSilentAddressRecord.name}";
      } else {
        addressesMap[address] = 'Active - Silent Payments';
      }
    }

    if (lightningAddress != null) {
      if (lightningAddress != address) {
        addressesMap[lightningAddress!] = 'LN';
      } else {
        addressesMap[address] = 'Active - LN';
      }
    }
  }

  void addLitecoinAddressTypes() {
    final lastP2wpkh = _addresses
        .where((addressRecord) =>
            _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2wpkh))
        .toList()
        .last;
    if (lastP2wpkh.address != address) {
      addressesMap[lastP2wpkh.address] = 'P2WPKH';
    } else {
      addressesMap[address] = 'Active - P2WPKH';
    }

    final lastMweb = _addresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.mweb));
    if (lastMweb.address != address) {
      addressesMap[lastMweb.address] = 'MWEB';
    } else {
      addressesMap[address] = 'Active - MWEB';
    }
  }

  void addP2PKHAddressTypes() {
    final lastP2pkh = _addresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, P2pkhAddressType.p2pkh));
    if (lastP2pkh.address != address) {
      addressesMap[lastP2pkh.address] = 'P2PKH';
    } else {
      addressesMap[address] = 'Active - P2PKH';
    }
  }

  @override
  Future<void> updateAddressesInBox() async {
    try {
      addressesMap.clear();
      addressesMap[address] = 'Active';

      allAddressesMap.clear();
      _addresses.forEach((addressRecord) {
        allAddressesMap[addressRecord.address] = addressRecord.name;
      });

      switch (walletInfo.type) {
        case WalletType.bitcoin:
          addBitcoinAddressTypes();
          break;
        case WalletType.litecoin:
          addLitecoinAddressTypes();
          break;
        case WalletType.bitcoinCash:
          addP2PKHAddressTypes();
          break;
        case WalletType.dogecoin:
          addP2PKHAddressTypes();
          break;
        default:
          break;
      }

      await saveAddressesInBox();
    } catch (e) {
      printV("updateAddresses $e");
    }
  }

  @action
  void updateAddress(String address, String label) {
    BaseBitcoinAddressRecord? foundAddress;
    _addresses.forEach((addressRecord) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
      }
    });
    silentAddresses.forEach((addressRecord) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
      }
    });
    mwebAddresses.forEach((addressRecord) {
      if (addressRecord.address == address) {
        foundAddress = addressRecord;
      }
    });

    if (foundAddress != null) {
      foundAddress!.setNewName(label);

      if (foundAddress is BitcoinAddressRecord) {
        final index = _addresses.indexOf(foundAddress);
        _addresses.remove(foundAddress);
        _addresses.insert(index, foundAddress as BitcoinAddressRecord);
      } else {
        final index = silentAddresses.indexOf(foundAddress as BitcoinSilentPaymentAddressRecord);
        silentAddresses.remove(foundAddress);
        silentAddresses.insert(index, foundAddress as BitcoinSilentPaymentAddressRecord);
      }
    }
  }

  @action
  void updateAddressesByMatch() {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      addressesByReceiveType.clear();
      addressesByReceiveType.addAll(silentAddresses);
      return;
    }

    addressesByReceiveType.clear();
    addressesByReceiveType.addAll(
      _addresses
          .where((addressRecord) =>
              _isCurrentAccountAddress(addressRecord) && _isAddressPageTypeMatch(addressRecord))
          .toList(),
    );
  }

  @action
  void updateReceiveAddresses() {
    receiveAddresses.removeRange(0, receiveAddresses.length);
    final newAddresses = _addresses.where((addressRecord) =>
        _isCurrentAccountAddress(addressRecord) &&
        !addressRecord.isHidden &&
        !addressRecord.isUsed);
    receiveAddresses.addAll(newAddresses);
  }

  @action
  void updateChangeAddresses() {
    changeAddresses.removeRange(0, changeAddresses.length);
    final newAddresses = _addresses.where((addressRecord) =>
        _isCurrentAccountAddress(addressRecord) &&
        addressRecord.isHidden &&
        !addressRecord.isUsed &&
        // TODO: feature to change change address type. For now fixed to p2wpkh, the cheapest type
        (walletInfo.type != WalletType.bitcoin || addressRecord.type == SegwitAddresType.p2wpkh));
    changeAddresses.addAll(newAddresses);
  }

  @action
  Future<void> discoverAddresses(
    List<BitcoinAddressRecord> addressList,
    bool isHidden,
    Future<String?> Function(BitcoinAddressRecord) getAddressHistory, {
    BitcoinAddressType type = SegwitAddresType.p2wpkh,
    required bool isLegacyDerivation,
    int accountIndex = 0,
  }) async {
    final newAddresses = await _createNewAddresses(
      gap,
      startIndex: addressList.length,
      isHidden: isHidden,
      isLegacyDerivation: isLegacyDerivation,
      type: type,
      accountIndex: accountIndex,
    );

    addAddresses(newAddresses);
    addressList.addAll(newAddresses);

    final addressesWithHistory = await Future.wait(newAddresses.map(getAddressHistory));
    final isLastAddressUsed = addressesWithHistory.last != null;

    if (isLastAddressUsed) {
      await discoverAddresses(
        addressList,
        isHidden,
        getAddressHistory,
        type: type,
        isLegacyDerivation: isLegacyDerivation,
        accountIndex: accountIndex,
      );
    }
  }

  @action
  Future<List<BitcoinAddressRecord>> discoverAddressesBatch(
    List<BitcoinAddressRecord> addressList,
    bool isHidden,
    Future<Set<String>> Function(List<BitcoinAddressRecord>) getUsedAddresses, {
    BitcoinAddressType type = SegwitAddresType.p2wpkh,
    required bool isLegacyDerivation,
    int accountIndex = 0,
  }) async {
    final newAddresses = await _createNewAddresses(
      gap,
      startIndex: addressList.length,
      isHidden: isHidden,
      type: type,
      isLegacyDerivation: isLegacyDerivation,
      accountIndex: accountIndex,
    );
    addAddresses(newAddresses);

    final usedAddresses = await getUsedAddresses(newAddresses);

    final hasUsedAddressInGap =
        newAddresses.any((addressRecord) => usedAddresses.contains(addressRecord.address));

    if (!hasUsedAddressInGap) {
      return newAddresses;
    }

    final updatedAddressList = [...addressList, ...newAddresses];

    final moreNewAddresses = await discoverAddressesBatch(
      updatedAddressList,
      isHidden,
      getUsedAddresses,
      type: type,
      isLegacyDerivation: isLegacyDerivation,
      accountIndex: accountIndex,
    );

    return [...newAddresses, ...moreNewAddresses];
  }

  Future<void> _generateInitialAddresses({
    BitcoinAddressType type = SegwitAddresType.p2wpkh,
    bool isLegacyDerivation = false,
    int accountIndex = 0,
  }) async {
    if (isLegacyDerivation && accountIndex != 0) return;

    var countOfReceiveAddresses = 0;
    var countOfHiddenAddresses = 0;

    _addresses.forEach((addr) {
      if (addr.accountIndex == accountIndex &&
          addr.type == type &&
          addr.isLegacyDerivation == isLegacyDerivation) {
        if (addr.isHidden) {
          countOfHiddenAddresses += 1;
        } else {
          countOfReceiveAddresses += 1;
        }
      }
    });

    if (countOfReceiveAddresses < defaultReceiveAddressesCount) {
      final addressesCount = defaultReceiveAddressesCount - countOfReceiveAddresses;
      final newAddresses = await _createNewAddresses(addressesCount,
          startIndex: countOfReceiveAddresses,
          isHidden: false,
          type: type,
          isLegacyDerivation: isLegacyDerivation,
          accountIndex: accountIndex);

      addAddresses(newAddresses);
    }

    if (countOfHiddenAddresses < defaultChangeAddressesCount) {
      final addressesCount = defaultChangeAddressesCount - countOfHiddenAddresses;
      final newAddresses = await _createNewAddresses(addressesCount,
          startIndex: countOfHiddenAddresses,
          isHidden: true,
          type: type,
          isLegacyDerivation: isLegacyDerivation,
          accountIndex: accountIndex);
      addAddresses(newAddresses);
    }
  }

  Future<List<BitcoinAddressRecord>> _createNewAddresses(
    int count, {
    int startIndex = 0,
    bool isHidden = false,
    BitcoinAddressType? type,
    bool isLegacyDerivation = false,
    int accountIndex = 0,
  }) async {
    final list = <BitcoinAddressRecord>[];

    for (var i = startIndex; i < count + startIndex; i++) {
      final addrType = type ?? addressPageType;

      try {
        final hd = _hdForAddressGeneration(
          isHidden: isHidden,
          type: addrType,
          isLegacyDerivation: isLegacyDerivation,
          accountIndex: accountIndex,
        );

        final address = BitcoinAddressRecord(
          await getAddressAsync(index: i, hd: hd, addressType: addrType),
          index: i,
          isHidden: isHidden,
          isHiddenChecked: true,
          isLegacyDerivation: isLegacyDerivation,
          type: addrType,
          network: network,
          accountIndex: accountIndex,
        );
        list.add(address);
      } on UnsupportedAddressTypeForAccountException catch (e) {
        printV("_createNewAddresses: skipping index $i, type $addrType, "
            "account $accountIndex: $e");
        return [];
      }
    }

    return list;
  }

  @action
  void addAddresses(Iterable<BitcoinAddressRecord> addresses) {
    final addressesSet = this._addresses.toSet();
    addressesSet.addAll(addresses);
    this._addresses.clear();
    this._addresses.addAll(addressesSet);
    updateAddressesByMatch();
    updateReceiveAddresses();
    updateChangeAddresses();
  }

  @action
  void addSilentAddresses(Iterable<BitcoinSilentPaymentAddressRecord> addresses) {
    final addressesSet = this.silentAddresses.toSet();
    addressesSet.addAll(addresses);
    this.silentAddresses.clear();
    this.silentAddresses.addAll(addressesSet);
    updateAddressesByMatch();
  }

  @action
  void addMwebAddresses(Iterable<BitcoinAddressRecord> addresses) {
    final addressesSet = this.mwebAddresses.toSet();
    addressesSet.addAll(addresses);
    this.mwebAddresses.clear();
    this.mwebAddresses.addAll(addressesSet);
    updateAddressesByMatch();
  }

  static const _validationTimeSlice = Duration(milliseconds: 16);

  Future<void> _validateAddresses() async {
    final addresses = _addresses.toList();
    final slice = Stopwatch()..start();

    for (final element in addresses) {
      try {
        await _validateAddress(element);
      } catch (e, s) {
        Zone.current.handleUncaughtError(e, s);
      }

      if (slice.elapsed >= _validationTimeSlice) {
        await Future<void>.delayed(Duration.zero);
        slice.reset();
      }
    }
  }

  Future<void> _validateAddress(BitcoinAddressRecord element) async {
    if (element.isHiddenChecked) return;

    if (element.type == SegwitAddresType.mweb) {
      // this would add a ton of startup lag for mweb addresses since we have 1000 of them
      return;
    }

    try {
      // Relabel only when the address re-derives from the other chain. A record from a path these
      // keys don't produce matches neither chain, so it keeps its label instead of flipping.
      final otherChainHd = _hdForAddressGeneration(
        isHidden: !element.isHidden,
        type: element.type,
        isLegacyDerivation: element.isLegacyDerivation,
        accountIndex: element.accountIndex,
      );
      final otherChainAddress =
          await getAddressAsync(index: element.index, hd: otherChainHd, addressType: element.type);
      if (element.address == otherChainAddress) {
        element.isHidden = !element.isHidden;
      }
      element.isHiddenChecked = true;
    } on UnsupportedAddressTypeForAccountException catch (e) {
      printV("_validateAddresses: skipping ${element.address}: $e");
    }
  }

  @override
  String get addressForBuy => super.addressForBuy;

  @action
  Future<void> setAddressType(BitcoinAddressType type) async {

    final needsAccountScopedHd =
        type is! LightningAddressType && type != SilentPaymentsAddresType.p2sp;

    BitcoinAddressType resolvedType = type;
    if (needsAccountScopedHd) {
      final accountIndex = walletInfo.type == WalletType.bitcoin ? currentAccountIndex : 0;
      if (!_isAddressTypeSupportedForAccount(type, accountIndex)) {
        resolvedType = EXTRA_ACCOUNT_ADDRESS_TYPES.first;
      }
    }

    _addressPageType = resolvedType;
    updateAddressesByMatch();
    walletInfo.addressPageType = addressPageType.toString();
    await walletInfo.save();
  }

  bool _isAddressPageTypeMatch(BitcoinAddressRecord addressRecord) {
    return _isAddressByType(addressRecord, addressPageType);
  }

  bool _isAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) => addr.type == type;

  bool _isUnusedReceiveAddressByType(
    BitcoinAddressRecord addressRecord,
    BitcoinAddressType type,
  ) {
    return _isCurrentAccountAddress(addressRecord) &&
        !addressRecord.isHidden &&
        !addressRecord.isUsed &&
        addressRecord.type == type;
  }

  @action
  void deleteSilentPaymentAddress(String address) {
    final addressRecord = silentAddresses.firstWhere((addressRecord) =>
        addressRecord.type == SilentPaymentsAddresType.p2sp && addressRecord.address == address);

    silentAddresses.remove(addressRecord);
    updateAddressesByMatch();
  }

  // Remove all addresses associated with a specific account index.
  @action
  Future<void> removeAddressesForAccount(int accountIndex) async {
    _addresses.removeWhere((addr) => addr.accountIndex == accountIndex);
    updateAddressesByMatch();
    updateReceiveAddresses();
    updateChangeAddresses();
    await updateAddressesInBox();
  }


  bool _isAddressTypeSupportedForAccount(BitcoinAddressType type, int accountIndex) {
    final effectiveAccountIndex = walletInfo.type == WalletType.bitcoin ? accountIndex : 0;
    return mainHdByTypeAndAccount[effectiveAccountIndex]?.containsKey(type) ?? false;
  }

  static BitcoinAddressType _resolveInitialAddressPageType({
    required BitcoinAddressType? initialAddressPageType,
    required WalletInfo walletInfo,
    required Map<int, Map<BitcoinAddressType, Bip32Slip10Secp256k1>> mainHdByTypeAndAccount,
    required int currentAccountIndex,
  }) {
    final resolved = initialAddressPageType ??
        (walletInfo.addressPageType != null
            ? walletInfo.addressPageType == LightningAddressType.p2l.value
                ? LightningAddressType.p2l
                : BitcoinAddressType.fromValue(walletInfo.addressPageType!)
            : SegwitAddresType.p2wpkh);

    // Non-account-scoped address types (Lightning, Silent Payments) don't need
    // an HD map entry.
    if (resolved is LightningAddressType || resolved == SilentPaymentsAddresType.p2sp) {
      return resolved;
    }

    final effectiveAccountIndex = walletInfo.type == WalletType.bitcoin ? currentAccountIndex : 0;

    final isValid = mainHdByTypeAndAccount[effectiveAccountIndex]?.containsKey(resolved) ?? false;

    if (!isValid) {
      return EXTRA_ACCOUNT_ADDRESS_TYPES.first;
    }

    return resolved;
  }

  Bip32Slip10Secp256k1 _hdForAddressGeneration({
    required bool isHidden,
    required BitcoinAddressType type,
    required bool isLegacyDerivation,
    int accountIndex = 0,
  }) {
    if (isLegacyDerivation) {
      if (accountIndex != 0) {
        throw UnsupportedAddressTypeForAccountException(
            "Legacy derivation is only supported for the first account");
      }

      return isHidden ? legacySideHd : legacyMainHd;
    }

    final effectiveAccountIndex = walletInfo.type == WalletType.bitcoin ? accountIndex : 0;

    final map = isHidden
        ? sideHdByTypeAndAccount[effectiveAccountIndex]
        : mainHdByTypeAndAccount[effectiveAccountIndex];

    if (map == null) {
      throw UnsupportedAddressTypeForAccountException(
          "HD map not found for account $effectiveAccountIndex");
    }

    final hd = map[type];
    if (hd == null) {
      throw UnsupportedAddressTypeForAccountException(
          "HD not found for account $accountIndex type $type");
    }

    return hd;
  }

  @action
  Future<void> setLightningAddress(String walletName, {String newAddress = ""}) async {
    if (lightningWallet == null) return;

    try {
      final path = await pathForWalletDir(name: walletName, type: WalletType.bitcoin);
      final initialized = await lightningWallet!.init(path);

      if (!initialized) {
        printV("Failed to initialize the lightning wallet");
        return;
      }

      lightningAddress = await lightningWallet!.getAddress();

      late final String username;

      if (newAddress.isEmpty) {
        if (lightningAddress != null) return;

        final randomNumber = Random.secure().nextInt(9999);
        final randomName = await generateName();
        username = "${randomName.replaceAll(" ", "")}$randomNumber".toLowerCase();
      } else {
        username = newAddress;
      }

      try {
        printV(username);
        lightningAddress = await lightningWallet!.registerAddress(username);
      } catch (e) {
        printV(e);
        printV(username);
        rethrow;
      }
    } on SdkError_NetworkError catch (_) {
    } on SdkError_SparkError catch (e) {
      if (!e.field0.contains("dns") && !e.field0.contains("TimedOut")) rethrow;
    } finally {
      lightningAddress ??= lightningWallet!.cachedAddress;
    }
  }
}
