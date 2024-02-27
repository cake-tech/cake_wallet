import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'electrum_wallet_addresses.g.dart';

class ElectrumWalletAddresses = ElectrumWalletAddressesBase with _$ElectrumWalletAddresses;

const List<BitcoinAddressType> ADDRESS_TYPES = [
  SegwitAddresType.p2wpkh,
  P2pkhAddressType.p2pkh,
  SegwitAddresType.p2tr,
  SegwitAddresType.p2wsh,
  P2shAddressType.p2wpkhInP2sh,
];

abstract class ElectrumWalletAddressesBase extends WalletAddresses with Store {
  ElectrumWalletAddressesBase(
    WalletInfo walletInfo, {
    required this.mainHd,
    required this.sideHd,
    required this.electrumClient,
    required this.network,
    List<BitcoinAddressRecord>? initialAddresses,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
  })  : _addresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? []).toSet()),
        addressesByReceiveType =
            ObservableList<BitcoinAddressRecord>.of((<BitcoinAddressRecord>[]).toSet()),
        receiveAddresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? [])
            .where((addressRecord) => !addressRecord.isHidden && !addressRecord.isUsed)
            .toSet()),
        changeAddresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? [])
            .where((addressRecord) => addressRecord.isHidden && !addressRecord.isUsed)
            .toSet()),
        currentReceiveAddressIndexByType = initialRegularAddressIndex ?? {},
        currentChangeAddressIndexByType = initialChangeAddressIndex ?? {},
        _addressPageType = walletInfo.addressPageType != null
            ? BitcoinAddressType.fromValue(walletInfo.addressPageType!)
            : SegwitAddresType.p2wpkh,
        super(walletInfo) {
    updateAddressesByMatch();
  }

  static const defaultReceiveAddressesCount = 22;
  static const defaultChangeAddressesCount = 17;
  static const gap = 20;

  static String toCashAddr(String address) => bitbox.Address.toCashAddress(address);

  static String toLegacy(String address) => bitbox.Address.toLegacyAddress(address);

  final ObservableList<BitcoinAddressRecord> _addresses;
  // Matched by addressPageType
  late ObservableList<BitcoinAddressRecord> addressesByReceiveType;
  final ObservableList<BitcoinAddressRecord> receiveAddresses;
  final ObservableList<BitcoinAddressRecord> changeAddresses;
  final ElectrumClient electrumClient;
  final BasedUtxoNetwork network;
  final bitcoin.HDWallet mainHd;
  final bitcoin.HDWallet sideHd;

  @observable
  BitcoinAddressType _addressPageType = SegwitAddresType.p2wpkh;

  @computed
  BitcoinAddressType get addressPageType => _addressPageType;

  @computed
  List<BitcoinAddressRecord> get allAddresses => _addresses;

  @override
  @computed
  String get address {
    String receiveAddress;

    final typeMatchingReceiveAddresses = receiveAddresses.where(_isAddressPageTypeMatch);

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

    return walletInfo.type == WalletType.bitcoinCash ? toCashAddr(receiveAddress) : receiveAddress;
  }

  @observable
  bool isEnabledAutoGenerateSubaddress = true;

  @override
  set address(String addr) {
    if (addr.startsWith('bitcoincash:')) {
      addr = toLegacy(addr);
    }
    final addressRecord = _addresses.firstWhere((addressRecord) => addressRecord.address == addr);

    previousAddressRecord = addressRecord;
    receiveAddresses.remove(addressRecord);
    receiveAddresses.insert(0, addressRecord);
  }

  @override
  String get primaryAddress => getAddress(index: 0, hd: mainHd, addressType: addressPageType);

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
    await _generateInitialAddresses();
    await _generateInitialAddresses(type: P2pkhAddressType.p2pkh);
    await _generateInitialAddresses(type: P2shAddressType.p2wpkhInP2sh);
    await _generateInitialAddresses(type: SegwitAddresType.p2tr);
    await _generateInitialAddresses(type: SegwitAddresType.p2wsh);
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
  Future<String> getChangeAddress() async {
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
    final address = changeAddresses[currentChangeAddressIndex].address;
    currentChangeAddressIndex += 1;
    return address;
  }

  BitcoinAddressRecord generateNewAddress({String label = ''}) {
    final newAddressIndex = addressesByReceiveType.fold(
        0, (int acc, addressRecord) => addressRecord.isHidden == false ? acc + 1 : acc);

    final address = BitcoinAddressRecord(
      getAddress(index: newAddressIndex, hd: mainHd, addressType: addressPageType),
      index: newAddressIndex,
      isHidden: false,
      name: label,
      type: addressPageType,
      network: network,
    );
    _addresses.add(address);
    updateAddressesByMatch();
    return address;
  }

  String getAddress(
          {required int index, required bitcoin.HDWallet hd, BitcoinAddressType? addressType}) =>
      '';

  @override
  Future<void> updateAddressesInBox() async {
    try {
      addressesMap.clear();
      addressesMap[address] = '';
      await saveAddressesInBox();
    } catch (e) {
      print(e.toString());
    }
  }

  @action
  void updateAddress(String address, String label) {
    if (address.startsWith('bitcoincash:')) {
      address = toLegacy(address);
    }
    final addressRecord =
        _addresses.firstWhere((addressRecord) => addressRecord.address == address);
    addressRecord.setNewName(label);
    final index = _addresses.indexOf(addressRecord);
    _addresses.remove(addressRecord);
    _addresses.insert(index, addressRecord);
  }

  @action
  void updateAddressesByMatch() {
    addressesByReceiveType.clear();
    addressesByReceiveType.addAll(_addresses.where(_isAddressPageTypeMatch).toList());
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
        addressRecord.type == SegwitAddresType.p2wpkh);
    changeAddresses.addAll(newAddresses);
  }

  @action
  Future<void> discoverAddresses(List<BitcoinAddressRecord> addressList, bool isHidden,
      Future<String?> Function(BitcoinAddressRecord, Set<String>) getAddressHistory,
      {BitcoinAddressType type = SegwitAddresType.p2wpkh}) async {
    if (!isHidden) {
      _validateSideHdAddresses(addressList.toList());
    }

    final newAddresses = await _createNewAddresses(gap,
        startIndex: addressList.length, isHidden: isHidden, type: type);
    addAddresses(newAddresses);

    final addressesWithHistory = await Future.wait(newAddresses
        .map((addr) => getAddressHistory(addr, _addresses.map((e) => e.address).toSet())));
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
        if (addr.isHidden) {
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
        getAddress(index: i, hd: _getHd(isHidden), addressType: type ?? addressPageType),
        index: i,
        isHidden: isHidden,
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

  void _validateSideHdAddresses(List<BitcoinAddressRecord> addrWithTransactions) {
    addrWithTransactions.forEach((element) {
      if (element.address !=
          getAddress(index: element.index, hd: mainHd, addressType: element.type))
        element.isHidden = true;
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

  bitcoin.HDWallet _getHd(bool isHidden) => isHidden ? sideHd : mainHd;
  bool _isAddressByType(BitcoinAddressRecord addr, BitcoinAddressType type) => addr.type == type;
}
