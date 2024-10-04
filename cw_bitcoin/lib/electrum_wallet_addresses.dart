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
    required this.bip32,
    required this.network,
    required this.isHardwareWallet,
    List<BitcoinAddressRecord>? initialAddresses,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    int initialSilentAddressIndex = 0,
    List<BitcoinAddressRecord>? initialMwebAddresses,
    BitcoinAddressType? initialAddressPageType,
  })  : _addresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? []).toSet()),
        addressesByReceiveType =
            ObservableList<BaseBitcoinAddressRecord>.of((<BitcoinAddressRecord>[]).toSet()),
        receiveAddresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? [])
            .where((addressRecord) => !addressRecord.isChange && !addressRecord.isUsed)
            .toSet()),
        changeAddresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? [])
            .where((addressRecord) => addressRecord.isChange && !addressRecord.isUsed)
            .toSet()),
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
    silentAddress = SilentPaymentOwner.fromPrivateKeys(
      b_scan: ECPrivate.fromHex(bip32.derive(SCAN_PATH).privateKey.toHex()),
      b_spend: ECPrivate.fromHex(bip32.derive(SPEND_PATH).privateKey.toHex()),
      network: network,
    );
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

  final ObservableList<BitcoinAddressRecord> _addresses;
  final ObservableList<BaseBitcoinAddressRecord> addressesByReceiveType;
  final ObservableList<BitcoinAddressRecord> receiveAddresses;
  final ObservableList<BitcoinAddressRecord> changeAddresses;
  // TODO: add this variable in `bitcoin_wallet_addresses` and just add a cast in cw_bitcoin to use it
  final ObservableList<BitcoinSilentPaymentAddressRecord> silentAddresses;
  // TODO: add this variable in `litecoin_wallet_addresses` and just add a cast in cw_bitcoin to use it
  final ObservableList<BitcoinAddressRecord> mwebAddresses;
  final BasedUtxoNetwork network;
  final Bip32Slip10Secp256k1 bip32;

  @observable
  SilentPaymentOwner? silentAddress;

  @observable
  late BitcoinAddressType _addressPageType;

  @computed
  BitcoinAddressType get addressPageType => _addressPageType;

  @observable
  String? activeSilentAddress;

  @computed
  List<BitcoinAddressRecord> get allAddresses => _addresses;

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
      final addressRecord = _addresses.firstWhere(
        (addressRecord) => addressRecord.address == addr,
      );

      previousAddressRecord = addressRecord;
      receiveAddresses.remove(addressRecord);
      receiveAddresses.insert(0, addressRecord);
    } catch (e) {
      print("ElectrumWalletAddressBase: set address ($addr): $e");
    }
  }

  @override
  String get primaryAddress =>
      getAddress(account: 0, index: 0, hd: bip32, addressType: addressPageType);

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
      await _generateInitialAddresses(type: P2pkhAddressType.p2pkh);
    } else if (walletInfo.type == WalletType.litecoin) {
      await _generateInitialAddresses(type: SegwitAddresType.p2wpkh);
      if ((Platform.isAndroid || Platform.isIOS) && !isHardwareWallet) {
        await _generateInitialAddresses(type: SegwitAddresType.mweb);
      }
    } else if (walletInfo.type == WalletType.bitcoin) {
      await _generateInitialAddresses();
      if (!isHardwareWallet) {
        await _generateInitialAddresses(type: P2pkhAddressType.p2pkh);
        await _generateInitialAddresses(type: P2shAddressType.p2wpkhInP2sh);
        await _generateInitialAddresses(type: SegwitAddresType.p2tr);
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
      {List<BitcoinUnspent>? inputs, List<BitcoinOutput>? outputs, bool isPegIn = false}) async {
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

    final address = BitcoinAddressRecord(
      getAddress(account: 0, index: newAddressIndex, hd: bip32, addressType: addressPageType),
      index: newAddressIndex,
      isChange: false,
      name: label,
      type: addressPageType,
      network: network,
    );
    _addresses.add(address);
    Future.delayed(Duration.zero, () => updateAddressesByMatch());
    return address;
  }

  BitcoinBaseAddress generateAddress({
    required int account,
    required int index,
    required Bip32Slip10Secp256k1 hd,
    required BitcoinAddressType addressType,
  }) {
    throw UnimplementedError();
  }

  String getAddress({
    required int account,
    required int index,
    required Bip32Slip10Secp256k1 hd,
    required BitcoinAddressType addressType,
  }) {
    return generateAddress(account: account, index: index, hd: hd, addressType: addressType)
        .toAddress(network);
  }

  Future<String> getAddressAsync({
    required int account,
    required int index,
    required Bip32Slip10Secp256k1 hd,
    required BitcoinAddressType addressType,
  }) async =>
      getAddress(account: account, index: index, hd: hd, addressType: addressType);

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

  void addBitcoinCashAddressTypes() {
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
    addressesByReceiveType.addAll(_addresses.where(_isAddressPageTypeMatch).toList());
  }

  @action
  void updateReceiveAddresses() {
    receiveAddresses.removeRange(0, receiveAddresses.length);
    final newAddresses =
        _addresses.where((addressRecord) => !addressRecord.isChange && !addressRecord.isUsed);
    receiveAddresses.addAll(newAddresses);
  }

  @action
  void updateChangeAddresses() {
    changeAddresses.removeRange(0, changeAddresses.length);
    final newAddresses = _addresses.where((addressRecord) =>
        addressRecord.isChange &&
        !addressRecord.isUsed &&
        // TODO: feature to change change address type. For now fixed to p2wpkh, the cheapest type
        (walletInfo.type != WalletType.bitcoin || addressRecord.type == SegwitAddresType.p2wpkh));
    changeAddresses.addAll(newAddresses);
  }

  @action
  Future<void> discoverAddresses(List<BitcoinAddressRecord> addressList, bool isHidden,
      Future<String?> Function(BitcoinAddressRecord) getAddressHistory,
      {BitcoinAddressType type = SegwitAddresType.p2wpkh}) async {
    final newAddresses = await _createNewAddresses(gap,
        startIndex: addressList.length, isHidden: isHidden, type: type);
    addAddresses(newAddresses);

    final addressesWithHistory = await Future.wait(newAddresses.map(getAddressHistory));
    final isLastAddressUsed = addressesWithHistory.last == addressList.last.address;

    if (isLastAddressUsed) {
      discoverAddresses(addressList, isHidden, getAddressHistory, type: type);
    }
  }

  Future<void> _generateInitialAddresses(
      {BitcoinAddressType type = SegwitAddresType.p2wpkh}) async {
    var countOfReceiveAddresses = 0;
    var countOfHiddenAddresses = 0;

    _addresses.forEach((addr) {
      if (addr.type == type) {
        if (addr.isChange) {
          countOfHiddenAddresses += 1;
          return;
        }

        countOfReceiveAddresses += 1;
      }
    });

    if (countOfReceiveAddresses < defaultReceiveAddressesCount) {
      final addressesCount = defaultReceiveAddressesCount - countOfReceiveAddresses;
      final newAddresses = await _createNewAddresses(addressesCount,
          startIndex: countOfReceiveAddresses, isHidden: false, type: type);
      addAddresses(newAddresses);
    }

    if (countOfHiddenAddresses < defaultChangeAddressesCount) {
      final addressesCount = defaultChangeAddressesCount - countOfHiddenAddresses;
      final newAddresses = await _createNewAddresses(addressesCount,
          startIndex: countOfHiddenAddresses, isHidden: true, type: type);
      addAddresses(newAddresses);
    }
  }

  Future<List<BitcoinAddressRecord>> _createNewAddresses(int count,
      {int startIndex = 0, bool isHidden = false, BitcoinAddressType? type}) async {
    final list = <BitcoinAddressRecord>[];

    for (var i = startIndex; i < count + startIndex; i++) {
      final address = BitcoinAddressRecord(
        await getAddressAsync(
            account: _getAccount(isHidden),
            index: i,
            hd: bip32,
            addressType: type ?? addressPageType),
        index: i,
        isChange: isHidden,
        type: type ?? addressPageType,
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
      if (!element.isChange &&
          element.address !=
              await getAddressAsync(
                account: 0,
                index: element.index,
                hd: bip32,
                addressType: element.type,
              )) {
        element.isChange = true;
      } else if (element.isChange &&
          element.address !=
              await getAddressAsync(
                account: 1,
                index: element.index,
                hd: bip32,
                addressType: element.type,
              )) {
        element.isChange = false;
      }
    });
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

  int _getAccount(bool isHidden) => isHidden ? 1 : 0;
  bool _isAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) => addr.type == type;

  bool _isUnusedReceiveAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) =>
      !addr.isChange && !addr.isUsed && addr.type == type;

  @action
  void deleteSilentPaymentAddress(String address) {
    final addressRecord = silentAddresses.firstWhere((addressRecord) =>
        addressRecord.type == SilentPaymentsAddresType.p2sp && addressRecord.address == address);

    silentAddresses.remove(addressRecord);
    updateAddressesByMatch();
  }
}
