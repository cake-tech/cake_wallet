import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/script_hash.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'electrum_wallet_addresses.g.dart';

class ElectrumWalletAddresses = ElectrumWalletAddressesBase
    with _$ElectrumWalletAddresses;

abstract class ElectrumWalletAddressesBase extends WalletAddresses with Store {
  ElectrumWalletAddressesBase(WalletInfo walletInfo,
      {@required List<BitcoinAddressRecord> initialAddresses,
      int initialRegularAddressIndex = 0,
      int initialChangeAddressIndex = 0,
      this.mainHd,
      this.sideHd,
      this.electrumClient,
      this.networkType})
      : addresses = ObservableList<BitcoinAddressRecord>.of(
          (initialAddresses ?? []).toSet()),
        receiveAddresses = ObservableList<BitcoinAddressRecord>.of(
          (initialAddresses ?? [])
            .where((addressRecord) => !addressRecord.isHidden && !addressRecord.isUsed)
        .toSet()),
        changeAddresses = ObservableList<BitcoinAddressRecord>.of(
          (initialAddresses ?? [])
            .where((addressRecord) => addressRecord.isHidden && !addressRecord.isUsed)
        .toSet()),
      super(walletInfo) {
    currentReceiveAddressIndex = initialRegularAddressIndex;
    currentChangeAddressIndex = initialChangeAddressIndex;
  }

  static const defaultReceiveAddressesCount = 22;
  static const defaultChangeAddressesCount = 17;
  static const gap = 20;

  final ObservableList<BitcoinAddressRecord> addresses;
  final ObservableList<BitcoinAddressRecord> receiveAddresses;
  final ObservableList<BitcoinAddressRecord> changeAddresses;
  final ElectrumClient electrumClient;
  final bitcoin.NetworkType networkType;
  final bitcoin.HDWallet mainHd;
  final bitcoin.HDWallet sideHd;

  @override
  @computed
  String get address => receiveAddresses.first.address;

  @override
  set address(String addr) => null;

  int currentReceiveAddressIndex;
  int currentChangeAddressIndex;

  @computed
  int get totalCountOfReceiveAddresses =>
    addresses.fold(0, (acc, addressRecord) {
      if (!addressRecord.isHidden) {
        return acc + 1;
      }
      return acc;
    });

  @computed
  int get totalCountOfChangeAddresses =>
    addresses.fold(0, (acc, addressRecord) {
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
      final newAddresses = await _createNewAddresses(
        gap,
        hd: sideHd,
        startIndex: totalCountOfChangeAddresses > 0
          ? totalCountOfChangeAddresses -  1
          : 0,
        isHidden: true);
      _addAddresses(newAddresses);
    }

    if (currentChangeAddressIndex >= changeAddresses.length) {
      currentChangeAddressIndex = 0;
    }

    updateChangeAddresses();
    final address = changeAddresses[currentChangeAddressIndex].address;
    currentChangeAddressIndex += 1;
    return address;
  }

  Future<BitcoinAddressRecord> generateNewAddress(
      {bool isHidden = false, bitcoin.HDWallet hd}) async {
    currentReceiveAddressIndex += 1;
    final address = BitcoinAddressRecord(
        getAddress(index: currentReceiveAddressIndex, hd: hd),
        index: currentReceiveAddressIndex,
        isHidden: isHidden);
    addresses.add(address);
    return address;
  }

  String getAddress({@required int index, @required bitcoin.HDWallet hd}) => '';

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
    final newAdresses = addresses
          .where((addressRecord) => !addressRecord.isHidden && !addressRecord.isUsed);
    receiveAddresses.addAll(newAdresses);
  }

  @action
  void updateChangeAddresses() {
    changeAddresses.removeRange(0, changeAddresses.length);
    final newAdresses = addresses
          .where((addressRecord) => addressRecord.isHidden && !addressRecord.isUsed);
    changeAddresses.addAll(newAdresses);
  }

  Future<void> _discoverAddresses(bitcoin.HDWallet hd, bool isHidden) async {
    var hasAddrUse = true;
    List<BitcoinAddressRecord> addrs;
    
    if (addresses.isNotEmpty) {
      addrs = addresses
        .where((addr) => addr.isHidden == isHidden)
        .toList();
    } else {
      addrs = await _createNewAddresses(
          isHidden
            ? defaultChangeAddressesCount
            : defaultReceiveAddressesCount,
          startIndex: 0,
          hd: hd,
          isHidden: isHidden);
    }
    
    while(hasAddrUse) {
      final addr = addrs.last.address;
      hasAddrUse = await _hasAddressUsed(addr);

      if (!hasAddrUse) {
        break;
      }

      final start = addrs.length;
      final count = start + gap;
      final batch = await _createNewAddresses(
        count,
        startIndex: start,
        hd: hd,
        isHidden: isHidden);
      addrs.addAll(batch);
    }

    if (addresses.length < addrs.length) {
      _addAddresses(addrs);
    }
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
      final newAddresses = await _createNewAddresses(
          addressesCount,
          startIndex: countOfReceiveAddresses,
          hd: mainHd,
          isHidden: false);
      addresses.addAll(newAddresses);
    }

    if (countOfHiddenAddresses < defaultChangeAddressesCount) {
      final addressesCount = defaultChangeAddressesCount - countOfHiddenAddresses;
      final newAddresses = await _createNewAddresses(
          addressesCount,
          startIndex: countOfHiddenAddresses,
          hd: sideHd,
          isHidden: true);
      addresses.addAll(newAddresses);
    }
  }

  Future<List<BitcoinAddressRecord>> _createNewAddresses(int count,
      {int startIndex = 0, bitcoin.HDWallet hd, bool isHidden = false}) async {
    final list = <BitcoinAddressRecord>[];

    for (var i = startIndex; i < count + startIndex; i++) {
      final address = BitcoinAddressRecord(
          getAddress(index: i, hd: hd),
          index: i,
          isHidden: isHidden);
      list.add(address);
    }

    return list;
  }

  void _addAddresses(Iterable<BitcoinAddressRecord> addresses) {
    final addressesSet = this.addresses.toSet();
    addressesSet.addAll(addresses);
    this.addresses.removeRange(0, this.addresses.length);
    this.addresses.addAll(addressesSet);
  }

  Future<bool> _hasAddressUsed(String address) async {
    final sh = scriptHash(address, networkType: networkType);
    final transactionHistory = await electrumClient.getHistory(sh);
    return transactionHistory.isNotEmpty;
  }
}