import 'dart:io' show Platform;

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'electrum_wallet_addresses.g.dart';

enum CWBitcoinDerivationType { old, electrum, bip39, mweb }

class ElectrumWalletAddresses = ElectrumWalletAddressesBase with _$ElectrumWalletAddresses;

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

abstract class ElectrumWalletAddressesBase extends WalletAddresses with Store {
  ElectrumWalletAddressesBase(
    WalletInfo walletInfo, {
    required this.hdWallets,
    required this.network,
    required this.isHardwareWallet,
    List<BitcoinAddressRecord>? initialAddresses,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    int initialSilentAddressIndex = 0,
    List<BitcoinAddressRecord>? initialMwebAddresses,
    BitcoinAddressType? initialAddressPageType,
  })  : _allAddresses = ObservableList.of(initialAddresses ?? []),
        addressesByReceiveType =
            ObservableList<BaseBitcoinAddressRecord>.of((<BitcoinAddressRecord>[]).toSet()),
        receiveAddresses = ObservableList<BitcoinAddressRecord>.of(
            (initialAddresses ?? []).where((addressRecord) => !addressRecord.isChange).toSet()),
        // TODO: feature to change change address type. For now fixed to p2wpkh, the cheapest type
        changeAddresses = ObservableList<BitcoinAddressRecord>.of(
            (initialAddresses ?? []).where((addressRecord) => addressRecord.isChange).toSet()),
        currentReceiveAddressIndexByType = initialRegularAddressIndex ?? {},
        currentChangeAddressIndexByType = initialChangeAddressIndex ?? {},
        _addressPageType = initialAddressPageType ??
            (walletInfo.addressPageType != null
                ? BitcoinAddressType.fromValue(walletInfo.addressPageType!)
                : SegwitAddresType.p2wpkh),
        silentAddresses = ObservableList<BitcoinSilentPaymentAddressRecord>.of(
            (initialSilentAddresses ?? []).toSet()),
        currentSilentAddressIndex = initialSilentAddressIndex,
        mwebAddresses =
            ObservableList<BitcoinAddressRecord>.of((initialMwebAddresses ?? []).toSet()),
        super(walletInfo) {
    // TODO: initial silent address, not every time
    silentAddress = SilentPaymentOwner.fromBip32(bip32);

    if (silentAddresses.length == 0) {
      silentAddresses.add(BitcoinSilentPaymentAddressRecord(
        silentAddress.toString(),
        labelIndex: 1,
        name: "",
        type: SilentPaymentsAddresType.p2sp,
      ));
      silentAddresses.add(BitcoinSilentPaymentAddressRecord(
        silentAddress!.toLabeledSilentPaymentAddress(0).toString(),
        name: "",
        labelIndex: 0,
        labelHex: BytesUtils.toHexString(silentAddress!.generateLabel(0)),
        type: SilentPaymentsAddresType.p2sp,
      ));
    }

    updateAddressesByMatch();
  }

  static const defaultReceiveAddressesCount = 22;
  static const defaultChangeAddressesCount = 17;
  static const gap = 20;

  final ObservableList<BitcoinAddressRecord> _allAddresses;
  final ObservableList<BaseBitcoinAddressRecord> addressesByReceiveType;
  final ObservableList<BitcoinAddressRecord> receiveAddresses;
  final ObservableList<BitcoinAddressRecord> changeAddresses;
  // TODO: add this variable in `bitcoin_wallet_addresses` and just add a cast in cw_bitcoin to use it
  final ObservableList<BitcoinSilentPaymentAddressRecord> silentAddresses;
  // TODO: add this variable in `litecoin_wallet_addresses` and just add a cast in cw_bitcoin to use it
  final ObservableList<BitcoinAddressRecord> mwebAddresses;
  final BasedUtxoNetwork network;

  final Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets;
  Bip32Slip10Secp256k1 get bip32 =>
      hdWallets[CWBitcoinDerivationType.bip39] ?? hdWallets[CWBitcoinDerivationType.electrum]!;

  final bool isHardwareWallet;

  @observable
  SilentPaymentOwner? silentAddress;

  @observable
  late BitcoinAddressType _addressPageType;

  @computed
  BitcoinAddressType get addressPageType => _addressPageType;

  @observable
  String? activeSilentAddress;

  @computed
  List<BitcoinAddressRecord> get allAddresses => _allAddresses.toList();

  @computed
  Set<String> get allScriptHashes =>
      _allAddresses.map((addressRecord) => addressRecord.scriptHash).toSet();

  BitcoinAddressRecord getFromAddresses(String address) {
    return _allAddresses.firstWhere((element) => element.address == address);
  }

  @override
  @computed
  String get address {
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      if (activeSilentAddress != null) {
        return activeSilentAddress!;
      }

      return silentAddress.toString();
    }

    String receiveAddress;

    final typeMatchingReceiveAddresses =
        receiveAddresses.where(_isAddressPageTypeMatch).where((addr) => !addr.isUsed);

    if ((isEnabledAutoGenerateSubaddress && receiveAddresses.isEmpty) ||
        typeMatchingReceiveAddresses.isEmpty) {
      receiveAddress = generateNewAddress().address;
    } else {
      final previousAddressMatchesType =
          previousAddressRecord != null && previousAddressRecord!.type == addressPageType;

      if (previousAddressMatchesType &&
          typeMatchingReceiveAddresses.first.address != addressesByReceiveType.first.address) {
        receiveAddress = previousAddressRecord!.address;
      } else {
        receiveAddress = typeMatchingReceiveAddresses.first.address;
      }
    }

    return receiveAddress;
  }

  @observable
  bool isEnabledAutoGenerateSubaddress = true;

  @override
  set address(String addr) {
    if (addr == "Silent Payments" && SilentPaymentsAddresType.p2sp != addressPageType) {
      return;
    }
    if (addressPageType == SilentPaymentsAddresType.p2sp) {
      late BitcoinSilentPaymentAddressRecord selected;
      try {
        selected = silentAddresses.firstWhere((addressRecord) => addressRecord.address == addr);
      } catch (_) {
        selected = silentAddresses[0];
      }

      if (selected.labelHex != null && silentAddress != null) {
        activeSilentAddress =
            silentAddress!.toLabeledSilentPaymentAddress(selected.labelIndex).toString();
      } else {
        activeSilentAddress = silentAddress!.toString();
      }
      return;
    }
    try {
      final addressRecord = _allAddresses.firstWhere(
        (addressRecord) => addressRecord.address == addr,
      );

      previousAddressRecord = addressRecord;
    } catch (e) {
      print("ElectrumWalletAddressBase: set address ($addr): $e");
    }
  }

  @override
  String get primaryAddress => _allAddresses.first.address;

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
        if (!addressRecord.isChange) {
          return acc + 1;
        }
        return acc;
      });

  @computed
  int get totalCountOfChangeAddresses => addressesByReceiveType.fold(0, (acc, addressRecord) {
        if (addressRecord.isChange) {
          return acc + 1;
        }
        return acc;
      });

  @override
  Future<void> init() async {
    if (walletInfo.type == WalletType.bitcoinCash) {
      await generateInitialAddresses(type: P2pkhAddressType.p2pkh);
    } else if (walletInfo.type == WalletType.litecoin) {
      await generateInitialAddresses(type: SegwitAddresType.p2wpkh);
      if ((Platform.isAndroid || Platform.isIOS) && !isHardwareWallet) {
        await generateInitialAddresses(type: SegwitAddresType.mweb);
      }
    } else if (walletInfo.type == WalletType.bitcoin) {
      await generateInitialAddresses(type: SegwitAddresType.p2wpkh);
      if (!isHardwareWallet) {
        await generateInitialAddresses(type: P2pkhAddressType.p2pkh);
        await generateInitialAddresses(type: P2shAddressType.p2wpkhInP2sh);
        await generateInitialAddresses(type: SegwitAddresType.p2tr);
        await generateInitialAddresses(type: SegwitAddresType.p2wsh);
      }
    }

    updateAddressesByMatch();
    updateReceiveAddresses();
    updateChangeAddresses();
    await updateAddressesInBox();

    if (currentReceiveAddressIndex >= receiveAddresses.length) {
      currentReceiveAddressIndex = 0;
    }

    if (currentChangeAddressIndex >= changeAddresses.length) {
      currentChangeAddressIndex = 0;
    }
  }

  @action
  Future<BitcoinAddressRecord> getChangeAddress({
    List<BitcoinUnspent>? inputs,
    List<BitcoinOutput>? outputs,
    bool isPegIn = false,
  }) async {
    updateChangeAddresses();

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
      final silentPaymentTweak = silentAddressRecord.labelHex;

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
    if (addressPageType == SilentPaymentsAddresType.p2sp && silentAddress != null) {
      final currentSilentAddressIndex = silentAddresses
              .where((addressRecord) => addressRecord.type != SegwitAddresType.p2tr)
              .length -
          1;

      this.currentSilentAddressIndex = currentSilentAddressIndex;

      final address = BitcoinSilentPaymentAddressRecord(
        silentAddress!.toLabeledSilentPaymentAddress(currentSilentAddressIndex).toString(),
        labelIndex: currentSilentAddressIndex,
        name: label,
        labelHex: BytesUtils.toHexString(silentAddress!.generateLabel(currentSilentAddressIndex)),
        type: SilentPaymentsAddresType.p2sp,
      );

      silentAddresses.add(address);
      Future.delayed(Duration.zero, () => updateAddressesByMatch());

      return address;
    }

    final newAddressIndex = addressesByReceiveType.fold(
        0, (int acc, addressRecord) => addressRecord.isChange == false ? acc + 1 : acc);

    final derivationInfo = BitcoinAddressUtils.getDerivationFromType(addressPageType);
    final address = BitcoinAddressRecord(
      getAddress(
        derivationType: CWBitcoinDerivationType.bip39,
        isChange: false,
        index: newAddressIndex,
        addressType: addressPageType,
        derivationInfo: derivationInfo,
      ),
      index: newAddressIndex,
      isChange: false,
      name: label,
      type: addressPageType,
      network: network,
      derivationInfo: BitcoinAddressUtils.getDerivationFromType(addressPageType),
      derivationType: CWBitcoinDerivationType.bip39,
    );
    _allAddresses.add(address);
    Future.delayed(Duration.zero, () => updateAddressesByMatch());
    return address;
  }

  BitcoinBaseAddress generateAddress({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) {
    throw UnimplementedError();
  }

  String getAddress({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) {
    return generateAddress(
      derivationType: derivationType,
      isChange: isChange,
      index: index,
      addressType: addressType,
      derivationInfo: derivationInfo,
    ).toAddress(network);
  }

  Future<String> getAddressAsync({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) async =>
      getAddress(
        derivationType: derivationType,
        isChange: isChange,
        index: index,
        addressType: addressType,
        derivationInfo: derivationInfo,
      );

  @action
  void addBitcoinAddressTypes() {
    final lastP2wpkh = _allAddresses
        .where((addressRecord) =>
            _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2wpkh))
        .toList()
        .last;
    if (lastP2wpkh.address != address) {
      addressesMap[lastP2wpkh.address] = 'P2WPKH';
    } else {
      addressesMap[address] = 'Active - P2WPKH';
    }

    final lastP2pkh = _allAddresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, P2pkhAddressType.p2pkh));
    if (lastP2pkh.address != address) {
      addressesMap[lastP2pkh.address] = 'P2PKH';
    } else {
      addressesMap[address] = 'Active - P2PKH';
    }

    final lastP2sh = _allAddresses.firstWhere((addressRecord) =>
        _isUnusedReceiveAddressByType(addressRecord, P2shAddressType.p2wpkhInP2sh));
    if (lastP2sh.address != address) {
      addressesMap[lastP2sh.address] = 'P2SH';
    } else {
      addressesMap[address] = 'Active - P2SH';
    }

    final lastP2tr = _allAddresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2tr));
    if (lastP2tr.address != address) {
      addressesMap[lastP2tr.address] = 'P2TR';
    } else {
      addressesMap[address] = 'Active - P2TR';
    }

    final lastP2wsh = _allAddresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2wsh));
    if (lastP2wsh.address != address) {
      addressesMap[lastP2wsh.address] = 'P2WSH';
    } else {
      addressesMap[address] = 'Active - P2WSH';
    }

    silentAddresses.forEach((addressRecord) {
      if (addressRecord.type != SilentPaymentsAddresType.p2sp || addressRecord.isChange) {
        return;
      }

      if (addressRecord.address != address) {
        addressesMap[addressRecord.address] = addressRecord.name.isEmpty
            ? "Silent Payments"
            : "Silent Payments - " + addressRecord.name;
      } else {
        addressesMap[address] = 'Active - Silent Payments';
      }
    });
  }

  @action
  void addLitecoinAddressTypes() {
    final lastP2wpkh = _allAddresses
        .where((addressRecord) =>
            _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.p2wpkh))
        .toList()
        .last;
    if (lastP2wpkh.address != address) {
      addressesMap[lastP2wpkh.address] = 'P2WPKH';
    } else {
      addressesMap[address] = 'Active - P2WPKH';
    }

    final lastMweb = _allAddresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, SegwitAddresType.mweb));
    if (lastMweb.address != address) {
      addressesMap[lastMweb.address] = 'MWEB';
    } else {
      addressesMap[address] = 'Active - MWEB';
    }
  }

  @action
  void addBitcoinCashAddressTypes() {
    final lastP2pkh = _allAddresses.firstWhere(
        (addressRecord) => _isUnusedReceiveAddressByType(addressRecord, P2pkhAddressType.p2pkh));
    if (lastP2pkh.address != address) {
      addressesMap[lastP2pkh.address] = 'P2PKH';
    } else {
      addressesMap[address] = 'Active - P2PKH';
    }
  }

  @override
  @action
  Future<void> updateAddressesInBox() async {
    try {
      addressesMap.clear();
      addressesMap[address] = 'Active';

      allAddressesMap.clear();
      _allAddresses.forEach((addressRecord) {
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
          addBitcoinCashAddressTypes();
          break;
        default:
          break;
      }

      await saveAddressesInBox();
    } catch (e) {
      print("updateAddresses $e");
    }
  }

  @action
  void updateAddress(String address, String label) {
    BaseBitcoinAddressRecord? foundAddress;
    _allAddresses.forEach((addressRecord) {
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

      if (foundAddress is! BitcoinAddressRecord) {
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
    addressesByReceiveType.addAll(_allAddresses.where(_isAddressPageTypeMatch).toList());
  }

  @action
  void updateReceiveAddresses() {
    receiveAddresses.removeRange(0, receiveAddresses.length);
    final newAddresses = _allAddresses.where((addressRecord) => !addressRecord.isChange);
    receiveAddresses.addAll(newAddresses);
  }

  @action
  void updateChangeAddresses() {
    changeAddresses.removeRange(0, changeAddresses.length);
    final newAddresses = _allAddresses.where((addressRecord) =>
        addressRecord.isChange &&
        (walletInfo.type != WalletType.bitcoin || addressRecord.type == SegwitAddresType.p2wpkh));
    changeAddresses.addAll(newAddresses);
  }

  @action
  Future<List<BitcoinAddressRecord>> discoverAddresses({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required BitcoinAddressType type,
    required BitcoinDerivationInfo derivationInfo,
  }) async {
    final gap = (isChange
        ? ElectrumWalletAddressesBase.defaultChangeAddressesCount
        : ElectrumWalletAddressesBase.defaultReceiveAddressesCount);

    final newAddresses = await _createNewAddresses(
      derivationType: derivationType,
      gap,
      isChange: isChange,
      type: type,
      derivationInfo: derivationInfo,
    );
    addAddresses(newAddresses);
    return newAddresses;
  }

  @action
  Future<void> generateInitialAddresses({required BitcoinAddressType type}) async {
    for (final derivationType in hdWallets.keys) {
      final derivationInfo = BitcoinAddressUtils.getDerivationFromType(
        type,
        isElectrum: derivationType == CWBitcoinDerivationType.electrum,
      );

      await discoverAddresses(
        derivationType: derivationType,
        isChange: false,
        type: type,
        derivationInfo: derivationInfo,
      );
      await discoverAddresses(
        derivationType: derivationType,
        isChange: true,
        type: type,
        derivationInfo: derivationInfo,
      );
    }
  }

  @action
  Future<List<BitcoinAddressRecord>> _createNewAddresses(
    int count, {
    required CWBitcoinDerivationType derivationType,
    required BitcoinDerivationInfo derivationInfo,
    bool isChange = false,
    BitcoinAddressType? type,
  }) async {
    final list = <BitcoinAddressRecord>[];
    final startIndex = (isChange ? receiveAddresses : changeAddresses)
        .where((addr) => addr.derivationType == derivationType && addr.type == type)
        .length;

    for (var i = startIndex; i < count + startIndex; i++) {
      final address = BitcoinAddressRecord(
        await getAddressAsync(
          derivationType: derivationType,
          isChange: isChange,
          index: i,
          addressType: type ?? addressPageType,
          derivationInfo: derivationInfo,
        ),
        index: i,
        isChange: isChange,
        isHidden: derivationType == CWBitcoinDerivationType.old,
        type: type ?? addressPageType,
        network: network,
        derivationInfo: derivationInfo,
        derivationType: derivationType,
      );
      list.add(address);
    }

    return list;
  }

  @action
  void updateAdresses(Iterable<BitcoinAddressRecord> addresses) {
    for (final address in addresses) {
      _allAddresses.replaceRange(address.index, address.index + 1, [address]);
    }
  }

  @action
  void addAddresses(Iterable<BitcoinAddressRecord> addresses) {
    this._allAddresses.addAll(addresses);
    updateAddressesByMatch();
    updateReceiveAddresses();
    updateChangeAddresses();

    this.hiddenAddresses.addAll(addresses
        .where((addressRecord) => addressRecord.isHidden)
        .map((addressRecord) => addressRecord.address));
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

  bool _isUnusedReceiveAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) {
    return !addr.isChange && !addr.isUsed && addr.type == type;
  }

  @action
  void deleteSilentPaymentAddress(String address) {
    final addressRecord = silentAddresses.firstWhere((addressRecord) =>
        addressRecord.type == SilentPaymentsAddresType.p2sp && addressRecord.address == address);

    silentAddresses.remove(addressRecord);
    updateAddressesByMatch();
  }
}
