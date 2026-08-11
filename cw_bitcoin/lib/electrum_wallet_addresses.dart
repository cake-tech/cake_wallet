import 'dart:io' show Platform;
import 'dart:math';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/lightning/lightning_addres_type.dart';
import 'package:cw_bitcoin/lightning/lightning_wallet.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/generate_name.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'electrum_wallet_addresses.g.dart';

abstract class ElectrumWalletAddresses = ElectrumWalletAddressesBase with _$ElectrumWalletAddresses;

const List<BitcoinAddressType> BITCOIN_ADDRESS_TYPES = [
  SegwitAddresType.p2wpkh,
  P2pkhAddressType.p2pkh,
  SegwitAddresType.p2tr,
  SegwitAddresType.p2wsh,
  P2shAddressType.p2wpkhInP2sh,
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

abstract class ElectrumWalletAddressesBase extends WalletAddresses with Store {
  ElectrumWalletAddressesBase(
    WalletInfo walletInfo, {
    required this.mainHdByType,
    required this.sideHdByType,
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
        _addressPageType = initialAddressPageType ??
            (walletInfo.addressPageType != null
                ? walletInfo.addressPageType == LightningAddressType.p2l.value
                    ? LightningAddressType.p2l
                    : BitcoinAddressType.fromValue(walletInfo.addressPageType!)
                : SegwitAddresType.p2wpkh),
        silentAddresses = ObservableList<BitcoinSilentPaymentAddressRecord>.of(
            (initialSilentAddresses ?? []).toSet()),
        currentSilentAddressIndex = initialSilentAddressIndex,
        mwebAddresses =
            ObservableList<BitcoinAddressRecord>.of((initialMwebAddresses ?? []).toSet()),
        lockedReceiveAddressByType = ObservableMap<BitcoinAddressType, String>(),
        lightningAddress = lightningWallet?.cachedAddress,
        super(walletInfo) {
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
  Map<BitcoinAddressType, Bip32Slip10Secp256k1> mainHdByType;
  Map<BitcoinAddressType, Bip32Slip10Secp256k1> sideHdByType;
  final Bip32Slip10Secp256k1 legacyMainHd;
  final Bip32Slip10Secp256k1 legacySideHd;
  final bool isHardwareWallet;
  final LightningWallet? lightningWallet;

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
  String get address {
    final _ = addressRefreshToggle;
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      if (activeSilentAddress != null) {
        return activeSilentAddress!;
      }

      return silentAddress.toString();
    }

    if (addressPageType == LightningAddressType.p2l) {
      return lightningAddress ??
          "Error: Unable to fetch your Lightning address, please check your network connection.";
    }

    final typeMatchingAddressesAll =
        _addresses.where((addr) => !addr.isHidden && _isAddressPageTypeMatch(addr)).toList();

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

    if (!isEnabledAutoGenerateSubaddress) {
      if (previousAddressRecord != null && previousAddressRecord!.type == addressPageType) {
        return previousAddressRecord!.address;
      }

      if (typeMatchingAddresses.isNotEmpty) {
        return typeMatchingAddresses.first.address;
      }

      return generateNewAddress().address;
    }

    if (typeMatchingAddresses.isEmpty || typeMatchingReceiveAddresses.isEmpty) {
      return generateNewAddress().address;
    }

    final locked = lockedReceiveAddressByType[addressPageType];
    if (locked != null && !hiddenAddresses.contains(locked)) return locked;

    final prev = previousAddressRecord;
    if (prev != null &&
        prev.type == addressPageType &&
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
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      final selected = silentAddresses.firstWhere((addressRecord) => addressRecord.address == addr);

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

      lockedReceiveAddressByType.remove(addressPageType);

      previousAddressRecord = addressRecord;
      receiveAddresses.remove(addressRecord);
      receiveAddresses.insert(0, addressRecord);

      if (isEnabledAutoGenerateSubaddress &&
          addressRecord.isUsed &&
          addressRecord.type == addressPageType) {
        lockedReceiveAddressByType[addressPageType] = addr;
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

    final mainHd = mainHdByType[addressPageType] ?? mainHdByType.values.first;
    return getAddress(index: 0, hd: mainHd, addressType: addressPageType);
  }

  String get payjoinCompatibleAddress {
    final addrType = (addressPageType == SilentPaymentsAddresType.p2sp ||
            addressPageType == LightningAddressType.p2l)
        ? SegwitAddresType.p2wpkh
        : addressPageType;

    final mainHd = mainHdByType[addrType] ?? mainHdByType.values.first;
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
  BitcoinAddressRecord? previousAddressRecord;

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
  Future<void> init() async {
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
      await _generateInitialAddresses(isLegacyDerivation: true);
      await _generateInitialAddresses();
      if (!isHardwareWallet) {
        await _generateInitialAddresses(type: P2pkhAddressType.p2pkh, isLegacyDerivation: true);
        await _generateInitialAddresses(type: P2pkhAddressType.p2pkh);

        await _generateInitialAddresses(
            type: P2shAddressType.p2wpkhInP2sh, isLegacyDerivation: true);
        await _generateInitialAddresses(type: P2shAddressType.p2wpkhInP2sh);

        await _generateInitialAddresses(type: SegwitAddresType.p2tr, isLegacyDerivation: true);
        await _generateInitialAddresses(type: SegwitAddresType.p2tr);

        await _generateInitialAddresses(type: SegwitAddresType.p2wsh, isLegacyDerivation: true);
        await _generateInitialAddresses(type: SegwitAddresType.p2wsh);
      }
    }

    updateAddressesByMatch();
    updateReceiveAddresses();
    updateChangeAddresses();
    _validateAddresses();
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
      final newAddresses = await _createNewAddresses(gap,
          startIndex: totalCountOfChangeAddresses > 0 ? totalCountOfChangeAddresses - 1 : 0,
          isHidden: true);
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

  @action
  BaseBitcoinAddressRecord generateNewAddress({String label = ''}) {
    if (addressPageType is LightningAddressType) {
      throw Exception("Lightning addresses cannot be rotated");
    }

    if (addressPageType == SilentPaymentsAddresType.p2sp && silentAddress != null) {
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

    final newAddressIndex = addressesByReceiveType.fold(
        0, (int acc, addressRecord) => addressRecord.isHidden == false ? acc + 1 : acc);

    final hd = _hdFor(isHidden: false, type: addressPageType, isLegacyDerivation: false);
    final address = BitcoinAddressRecord(
      getAddress(index: newAddressIndex, hd: hd, addressType: addressPageType),
      index: newAddressIndex,
      isHidden: false,
      isLegacyDerivation: false,
      name: label,
      type: addressPageType,
      network: network,
    );
    Future.delayed(Duration.zero, () {
      _addresses.add(address);
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
        .toList()
        .last;
    if (lastP2wpkh.address != address) {
      addressesMap[lastP2wpkh.address] = 'P2WPKH';
    } else {
      addressesMap[address] = 'Active - P2WPKH';
    }

    final lastP2pkh = _addresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, P2pkhAddressType.p2pkh));
    if (lastP2pkh.address != address) {
      addressesMap[lastP2pkh.address] = 'P2PKH';
    } else {
      addressesMap[address] = 'Active - P2PKH';
    }

    final lastP2sh = _addresses.firstWhere((addressRecord) =>
        _isUnusedReceiveAddressByType(addressRecord, P2shAddressType.p2wpkhInP2sh));
    if (lastP2sh.address != address) {
      addressesMap[lastP2sh.address] = 'P2SH';
    } else {
      addressesMap[address] = 'Active - P2SH';
    }

    final lastP2tr = _addresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2tr));
    if (lastP2tr.address != address) {
      addressesMap[lastP2tr.address] = 'P2TR';
    } else {
      addressesMap[address] = 'Active - P2TR';
    }

    final lastP2wsh = _addresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2wsh));
    if (lastP2wsh.address != address) {
      addressesMap[lastP2wsh.address] = 'P2WSH';
    } else {
      addressesMap[address] = 'Active - P2WSH';
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
      _addresses.where(_isAddressPageTypeMatch).toList(),
    );
  }

  @action
  void updateReceiveAddresses() {
    receiveAddresses.removeRange(0, receiveAddresses.length);
    final newAddresses =
        _addresses.where((addressRecord) => !addressRecord.isHidden && !addressRecord.isUsed);
    receiveAddresses.addAll(newAddresses);
  }

  @action
  void updateChangeAddresses() {
    changeAddresses.removeRange(0, changeAddresses.length);
    final newAddresses = _addresses.where((addressRecord) =>
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
  }) async {
    final newAddresses = await _createNewAddresses(
      gap,
      startIndex: addressList.length,
      isHidden: isHidden,
      isLegacyDerivation: isLegacyDerivation,
      type: type,
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
  }) async {
    final newAddresses = await _createNewAddresses(
      gap,
      startIndex: addressList.length,
      isHidden: isHidden,
      type: type,
      isLegacyDerivation: isLegacyDerivation,
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
    );

    return [...newAddresses, ...moreNewAddresses];
  }

  Future<void> _generateInitialAddresses(
      {BitcoinAddressType type = SegwitAddresType.p2wpkh, bool isLegacyDerivation = false}) async {
    // Legacy derivation produces the same addresses as standard for these types.
    // Don't generate a legacy set to avoid duplicates.
    if (isLegacyDerivation && (type == SegwitAddresType.p2wpkh || type == SegwitAddresType.p2wsh)) {
      return;
    }

    var countOfReceiveAddresses = 0;
    var countOfHiddenAddresses = 0;

    _addresses.forEach((addr) {
      if (addr.type == type && addr.isLegacyDerivation == isLegacyDerivation) {
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
          isLegacyDerivation: isLegacyDerivation);
      addAddresses(newAddresses);
    }

    if (countOfHiddenAddresses < defaultChangeAddressesCount) {
      final addressesCount = defaultChangeAddressesCount - countOfHiddenAddresses;
      final newAddresses = await _createNewAddresses(addressesCount,
          startIndex: countOfHiddenAddresses,
          isHidden: true,
          type: type,
          isLegacyDerivation: isLegacyDerivation);
      addAddresses(newAddresses);
    }
  }

  Future<List<BitcoinAddressRecord>> _createNewAddresses(int count,
      {int startIndex = 0,
      bool isHidden = false,
      BitcoinAddressType? type,
      bool isLegacyDerivation = false}) async {
    final list = <BitcoinAddressRecord>[];

    for (var i = startIndex; i < count + startIndex; i++) {
      final addrType = type ?? addressPageType;
      final hd = _hdFor(isHidden: isHidden, type: addrType, isLegacyDerivation: isLegacyDerivation);

      final address = BitcoinAddressRecord(
        await getAddressAsync(index: i, hd: hd, addressType: addrType),
        index: i,
        isHidden: isHidden,
        isLegacyDerivation: isLegacyDerivation,
        type: addrType,
        network: network,
      );
      list.add(address);
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

  void _validateAddresses() {
    _addresses.forEach((element) async {
      if (element.type == SegwitAddresType.mweb) {
        // this would add a ton of startup lag for mweb addresses since we have 1000 of them
        return;
      }

      final mainHd = _hdFor(
          isHidden: false, type: element.type, isLegacyDerivation: element.isLegacyDerivation);
      final sideHd = _hdFor(
          isHidden: true, type: element.type, isLegacyDerivation: element.isLegacyDerivation);
      if (!element.isHidden &&
          element.address !=
              await getAddressAsync(index: element.index, hd: mainHd, addressType: element.type)) {
        element.isHidden = true;
      } else if (element.isHidden &&
          element.address !=
              await getAddressAsync(index: element.index, hd: sideHd, addressType: element.type)) {
        element.isHidden = false;
      }
    });
  }

  @override
  String get addressForBuy => super.addressForBuy;

  @action
  Future<void> setAddressType(BitcoinAddressType type) async {
    _addressPageType = type;
    updateAddressesByMatch();
    walletInfo.addressPageType = addressPageType.toString();
    await walletInfo.save();
  }

  bool _isAddressPageTypeMatch(BitcoinAddressRecord addressRecord) {
    return _isAddressByType(addressRecord, addressPageType);
  }

  bool _isAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) => addr.type == type;

  bool _isUnusedReceiveAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) =>
      !addr.isHidden && !addr.isUsed && addr.type == type;

  @action
  void deleteSilentPaymentAddress(String address) {
    final addressRecord = silentAddresses.firstWhere((addressRecord) =>
        addressRecord.type == SilentPaymentsAddresType.p2sp && addressRecord.address == address);

    silentAddresses.remove(addressRecord);
    updateAddressesByMatch();
  }

  Bip32Slip10Secp256k1 _hdFor({
    required bool isHidden,
    required BitcoinAddressType type,
    required bool isLegacyDerivation,
  }) {
    if (isLegacyDerivation) return isHidden ? legacySideHd : legacyMainHd;

    final map = isHidden ? sideHdByType : mainHdByType;
    final hd = map[type];
    if (hd == null) throw Exception("HD not found for type $type");
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
