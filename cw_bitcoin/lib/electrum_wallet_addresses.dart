import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/script_hash.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'dart:math';

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
      : super(walletInfo) {
    currentReceiveAddressIndex = initialRegularAddressIndex;
    currentChangeAddressIndex = initialChangeAddressIndex;
    addresses = ObservableList<BitcoinAddressRecord>.of(
        (initialAddresses ?? []).toSet());
  }

  static const defaultReceiveAddressesCount = 22;
  static const defaultChangeAddressesCount = 17;
  static const gap = 20;

  @override
  @observable
  String address;

  int currentReceiveAddressIndex;
  int currentChangeAddressIndex;
  ElectrumClient electrumClient;
  bitcoin.NetworkType networkType;
  bitcoin.HDWallet mainHd;
  bitcoin.HDWallet sideHd;
  ObservableList<BitcoinAddressRecord> addresses;

  List<BitcoinAddressRecord> get receiveAddresses => addresses
      .where((addr) => !addr.isHidden && !addr.isUsed)
      .toList();

  List<BitcoinAddressRecord> get changeAddresses => addresses
      .where((addr) => addr.isHidden && !addr.isUsed)
      .toList();

  List<BitcoinAddressRecord> get totalReceiveAddresses => addresses
      .where((addr) => !addr.isHidden)
      .toList();

  List<BitcoinAddressRecord> get totalChangeAddresses => addresses
      .where((addr) => addr.isHidden)
      .toList();

  Future<void> discoverAddresses() async {
    await _discoverAddresses(mainHd, false);
    await _discoverAddresses(sideHd, true);
    await updateAddressesInBox();
  }

  @override
  Future<void> init() async {
    await _generateInitialAddresses();

    if (receiveAddresses.isEmpty) {
      final newAddresses = await _createNewAddresses(
        gap,
        hd: mainHd,
        startIndex: totalReceiveAddresses.length > 0 
          ? totalReceiveAddresses.length - 1
          : 0,
        isHidden: false);
      _addAddresses(newAddresses);
    } else if (currentReceiveAddressIndex >= receiveAddresses.length) {
      currentReceiveAddressIndex = 0;
    }

    address = receiveAddresses[currentReceiveAddressIndex].address;
    await updateAddressesInBox();
  }

  @action
  Future<void> nextReceiveAddress() async {
    if (receiveAddresses.isEmpty) {
      final newAddresses = await _createNewAddresses(
        gap,
        hd: mainHd,
        startIndex: totalReceiveAddresses.length > 0 
          ? totalReceiveAddresses.length - 1
          : 0,
        isHidden: false);
      _addAddresses(newAddresses);
    } else if (currentReceiveAddressIndex >= receiveAddresses.length) {
      currentReceiveAddressIndex = 0;
    }

    address = receiveAddresses[currentReceiveAddressIndex].address;
    currentReceiveAddressIndex += 1;
    await updateAddressesInBox();
  }

  @action
  Future<String> getChangeAddress() async {
    if (changeAddresses.isEmpty) {
      final newAddresses = await _createNewAddresses(
        gap,
        hd: sideHd,
        startIndex: totalChangeAddresses.length > 0
          ? totalChangeAddresses.length -  1
          : 0,
        isHidden: true);
      _addAddresses(newAddresses);
    } else if (currentChangeAddressIndex >= changeAddresses.length) {
      currentChangeAddressIndex = 0;
    }

    
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

  void randomizeAddress() {
    const minCountOfVisibleAddresses = 5;
    final random = Random();
    var availableAddresses = addresses
      .where((addr) => !addr.isHidden)
      .toList();

    if (availableAddresses.length < minCountOfVisibleAddresses) {
      availableAddresses = addresses;
    }

    address = availableAddresses[random.nextInt(availableAddresses.length)].address;
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
      hasAddrUse = await _validateAddressUsing(addr);

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

  Future<bool> _validateAddressUsing(String address) async {
    final sh = scriptHash(address, networkType: networkType);
    final balance = await electrumClient.getBalance(sh);
    return balance.isEmpty;
  }
}