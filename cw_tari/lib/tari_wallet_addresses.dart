import 'dart:developer';

import 'package:cw_core/wallet_addresses.dart';
import 'package:mobx/mobx.dart';

part 'tari_addresses.g.dart';

class TariWalletAddresses = TariWalletAddressesBase with _$TariWalletAddresses;

abstract class TariWalletAddressesBase extends WalletAddresses with Store {
  TariWalletAddressesBase(super.walletInfo) : address = '';

  @override
  @observable
  String address;

  @override
  String get primaryAddress => address;

  @override
  Future<void> init() async {
    address = walletInfo.address;
    await updateAddressesInBox();
  }

  @override
  Future<void> updateAddressesInBox() async {
    try {
      addressesMap.clear();
      addressesMap[address] = '';
      await saveAddressesInBox();
    } catch (e) {
      log(e.toString());
    }
  }
}
