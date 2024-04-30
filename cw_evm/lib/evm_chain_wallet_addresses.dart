import 'dart:developer';

import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'evm_chain_wallet_addresses.g.dart';

class EVMChainWalletAddresses = EVMChainWalletAddressesBase with _$EVMChainWalletAddresses;

abstract class EVMChainWalletAddressesBase extends WalletAddresses with Store {
  EVMChainWalletAddressesBase(WalletInfo walletInfo)
      : address = '',
        super(walletInfo);

  @override
  @observable
  String address;

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
