import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/script_hash.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'electrum_wallet_addresses.g.dart';

class ElectrumWalletAddresses = ElectrumWalletAddressesBase with _$ElectrumWalletAddresses;

abstract class ElectrumWalletAddressesBase extends WalletAddresses with Store {
  ElectrumWalletAddressesBase(
    WalletInfo walletInfo, {
    required this.mainHd,
    required this.sideHd,
    required this.electrumClient,
    required this.network,
    String? initialAddressPageType,
    List<BitcoinAddressRecord>? initialAddresses,
    Map<String, int> initialRegularAddressIndex = const {},
    Map<String, int> initialChangeAddressIndex = const {},
  })  : addresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? []).toSet()),
        receiveAddresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? [])
            .where((addressRecord) => !addressRecord.isHidden && !addressRecord.isUsed)
            .toSet()),
        changeAddresses = ObservableList<BitcoinAddressRecord>.of((initialAddresses ?? [])
            .where((addressRecord) => addressRecord.isHidden && !addressRecord.isUsed)
            .toSet()),
        currentReceiveAddressIndexByType = initialRegularAddressIndex,
        currentChangeAddressIndexByType = initialChangeAddressIndex,
        _addressPageType = walletInfo.addressPageType != null
            ? BitcoinAddressType.fromValue(
                walletInfo.addressPageType ?? BitcoinAddressType.p2wpkh.toString())
            : BitcoinAddressType.p2wpkh,
        super(walletInfo);

  static const defaultReceiveAddressesCount = 22;
  static const defaultChangeAddressesCount = 17;
  static const gap = 20;

  static String toCashAddr(String address) => bitbox.Address.toCashAddress(address);

  final ObservableList<BitcoinAddressRecord> addresses;
  final ObservableList<BitcoinAddressRecord> receiveAddresses;
  final ObservableList<BitcoinAddressRecord> changeAddresses;
  final ElectrumClient electrumClient;
  final BasedUtxoNetwork network;
  final bitcoin.HDWallet mainHd;
  final bitcoin.HDWallet sideHd;

  @observable
  BitcoinAddressType _addressPageType = BitcoinAddressType.p2wpkh;

  @computed
  BitcoinAddressType get addressPageType => _addressPageType;

  @computed
  @override
  String get addressPageTypeStr => addressPageType.toString();

  @override
  @computed
  String get address {
    if (receiveAddresses.isEmpty) {
      final address = generateNewAddress().address;
      return walletInfo.type == WalletType.bitcoinCash ? toCashAddr(address) : address;
    }

    try {
      final receiveAddress = receiveAddresses.firstWhere((address) {
        return addressPageType == BitcoinAddressType.p2wpkh
            ? address.type == null || address.type == addressPageType
            : address.type == addressPageType;
      }).address;

      return walletInfo.type == WalletType.bitcoinCash
          ? toCashAddr(receiveAddress)
          : receiveAddress;
    } catch (_) {}

    return receiveAddresses.first.address;
  }

  @override
  String get primaryAddress => getAddress(index: 0, hd: mainHd);

  @override
  set address(String addr) => null;

  Map<String, int> currentReceiveAddressIndexByType = {};

  int get currentReceiveAddressIndex =>
      currentReceiveAddressIndexByType[_addressPageType.toString()] ?? 0;

  void set currentReceiveAddressIndex(int index) =>
      currentReceiveAddressIndexByType[_addressPageType.toString()] = index;

  Map<String, int> currentChangeAddressIndexByType = {};

  int get currentChangeAddressIndex =>
      currentChangeAddressIndexByType[_addressPageType.toString()] ?? 0;

  void set currentChangeAddressIndex(int index) =>
      currentChangeAddressIndexByType[_addressPageType.toString()] = index;

  @computed
  int get totalCountOfReceiveAddresses => addresses.fold(0, (acc, addressRecord) {
        if (!addressRecord.isHidden) {
          return acc + 1;
        }
        return acc;
      });

  @computed
  int get totalCountOfChangeAddresses => addresses.fold(0, (acc, addressRecord) {
        if (addressRecord.isHidden) {
          return acc + 1;
        }
        return acc;
      });

  Future<void> discoverAddresses() async {
    await _discoverAddresses(mainHd, false);
    await _discoverAddresses(sideHd, true);
    await updateAddressesInBox();
  }

  @override
  Future<void> init() async {
    await _generateInitialAddresses();
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
          hd: sideHd,
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

  @action
  BitcoinAddressRecord generateNewAddress(
      {bitcoin.HDWallet? hd, bool isHidden = false, String? label}) {
    currentReceiveAddressIndex += 1;
    // FIX-ME: Check logic for whichi HD should be used here  ???
    final address = BitcoinAddressRecord(
        getAddress(
            index: currentReceiveAddressIndex, hd: hd ?? sideHd, addressType: addressPageType),
        index: currentReceiveAddressIndex,
        isHidden: isHidden);
    addresses.add(address);
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
  void updateReceiveAddresses() {
    receiveAddresses.removeRange(0, receiveAddresses.length);
    final newAdresses =
        addresses.where((addressRecord) => !addressRecord.isHidden && !addressRecord.isUsed);
    receiveAddresses.addAll(newAdresses);
  }

  @action
  void updateChangeAddresses() {
    changeAddresses.removeRange(0, changeAddresses.length);
    final newAdresses =
        addresses.where((addressRecord) => addressRecord.isHidden && !addressRecord.isUsed);
    changeAddresses.addAll(newAdresses);
  }

  @action
  Future<void> _discoverAddresses(bitcoin.HDWallet hd, bool isHidden,
      {BitcoinAddressType? addressType}) async {
    var hasAddrUse = true;
    List<BitcoinAddressRecord> addrs;

    if (addresses.where((addr) => addr.type == addressPageType).isNotEmpty) {
      addrs = addresses.where((addr) => addr.isHidden == isHidden).toList();
    } else {
      addrs = await _createNewAddresses(
          isHidden ? defaultChangeAddressesCount : defaultReceiveAddressesCount,
          startIndex: 0,
          hd: hd,
          isHidden: isHidden,
          addressType: addressType);
    }

    while (hasAddrUse) {
      final addr = addrs.last.address;
      hasAddrUse = await _hasAddressUsed(addr);

      if (!hasAddrUse) {
        break;
      }

      final start = addrs.length;
      final count = start + gap;
      final batch = await _createNewAddresses(count,
          startIndex: start, hd: hd, isHidden: isHidden, addressType: addressType);
      addrs.addAll(batch);
    }

    addAddresses(addrs);
  }

  Future<void> _generateInitialAddresses() async {
    var countOfReceiveAddresses = 0;
    var countOfHiddenAddresses = 0;

    addresses.forEach((addr) {
      if (addr.isHidden) {
        countOfHiddenAddresses += 1;
        return;
      }

      countOfReceiveAddresses += 1;
    });

    if (countOfReceiveAddresses < defaultReceiveAddressesCount) {
      final addressesCount = defaultReceiveAddressesCount - countOfReceiveAddresses;
      final newAddresses = await _createNewAddresses(addressesCount,
          startIndex: countOfReceiveAddresses,
          hd: mainHd,
          isHidden: false,
          addressType: addressPageType);
      addresses.addAll(newAddresses);
    }

    if (countOfHiddenAddresses < defaultChangeAddressesCount) {
      final addressesCount = defaultChangeAddressesCount - countOfHiddenAddresses;
      final newAddresses = await _createNewAddresses(addressesCount,
          startIndex: countOfHiddenAddresses,
          hd: sideHd,
          isHidden: true,
          addressType: addressPageType);
      addresses.addAll(newAddresses);
    }
  }

  Future<List<BitcoinAddressRecord>> _createNewAddresses(int count,
      {required bitcoin.HDWallet hd,
      int startIndex = 0,
      bool isHidden = false,
      BitcoinAddressType? addressType}) async {
    final list = <BitcoinAddressRecord>[];

    for (var i = startIndex; i < count + startIndex; i++) {
      final address = BitcoinAddressRecord(getAddress(index: i, hd: hd, addressType: addressType),
          index: i, isHidden: isHidden, type: addressType);
      list.add(address);
    }

    return list;
  }

  @action
  void addAddresses(Iterable<BitcoinAddressRecord> addresses) {
    final addressesSet = this.addresses.toSet();
    addressesSet.addAll(addresses);
    this.addresses.removeRange(0, this.addresses.length);
    this.addresses.addAll(addressesSet);
  }

  Future<bool> _hasAddressUsed(String address) async {
    final sh = scriptHash(address, network: network);
    final transactionHistory = await electrumClient.getHistory(sh);
    return transactionHistory.isNotEmpty;
  }

  @action
  Future<void> setAddressType(BitcoinAddressType type) async {
    _addressPageType = type;

    await _discoverAddresses(mainHd, false, addressType: addressPageType);
    updateReceiveAddresses();
    await saveAddressesInBox();
  }
}
