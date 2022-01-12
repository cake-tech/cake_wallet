import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/bitcoin_address_record.dart';
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
      int accountIndex = 0,
      this.mainHd,
      this.sideHd})
      : super(walletInfo) {
    this.accountIndex = accountIndex;
    addresses = ObservableList<BitcoinAddressRecord>.of(
        (initialAddresses ?? []).toSet());
  }

  static const regularAddressesCount = 22;
  static const hiddenAddressesCount = 17;

  @override
  @observable
  String address;

  bitcoin.HDWallet mainHd;
  bitcoin.HDWallet sideHd;

  ObservableList<BitcoinAddressRecord> addresses;

  List<BitcoinAddressRecord> get availableAddresses => addresses
      .where((addr) => addr.isHidden)
      .toList();

  int accountIndex;

  @override
  Future<void> init() async {
    await generateAddresses();
    final _availableAddresses = availableAddresses;

    if (accountIndex >= _availableAddresses.length) {
      accountIndex = 0;
    }

    address = _availableAddresses[accountIndex].address;
    await updateAddressesInBox();
  }

  @action
  Future<void> nextAddress() async {
    accountIndex += 1;
    final _availableAddresses = availableAddresses;

    if (accountIndex >= _availableAddresses.length) {
      accountIndex = 0;
    }

    address = _availableAddresses[accountIndex].address;

    await updateAddressesInBox();
  }

  Future<void> generateAddresses() async {
    final regularAddresses = <BitcoinAddressRecord>[];
    final hiddenAddresses = <BitcoinAddressRecord>[];

    addresses.forEach((addr) {
      if (addr.isHidden) {
        hiddenAddresses.add(addr);
        return;
      }

      regularAddresses.add(addr);
    });

    if (regularAddresses.length < regularAddressesCount) {
      final addressesCount = regularAddressesCount - regularAddresses.length;
      await generateNewAddresses(addressesCount,
          startIndex: regularAddresses.length, hd: mainHd, isHidden: false);
    }

    if (hiddenAddresses.length < hiddenAddressesCount) {
      final addressesCount = hiddenAddressesCount - hiddenAddresses.length;
      await generateNewAddresses(addressesCount,
          startIndex: hiddenAddresses.length, hd: sideHd, isHidden: true);
    }
  }

  Future<BitcoinAddressRecord> generateNewAddress(
      {bool isHidden = false, bitcoin.HDWallet hd}) async {
    accountIndex += 1;
    final address = BitcoinAddressRecord(
        getAddress(index: accountIndex, hd: hd),
        index: accountIndex,
        isHidden: isHidden);
    addresses.add(address);
    return address;
  }

  Future<List<BitcoinAddressRecord>> generateNewAddresses(int count,
      {int startIndex = 0, bitcoin.HDWallet hd, bool isHidden = false}) async {
    final list = <BitcoinAddressRecord>[];

    for (var i = startIndex; i < count + startIndex; i++) {
      final address = BitcoinAddressRecord(getAddress(index: i, hd: hd),
          index: i, isHidden: isHidden);
      list.add(address);
    }

    addresses.addAll(list);
    return list;
  }

  /*Future<void> updateAddress(String address) async {
    for (final addr in addresses) {
      if (addr.address == address) {
        await save();
        break;
      }
    }
  }*/

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
}