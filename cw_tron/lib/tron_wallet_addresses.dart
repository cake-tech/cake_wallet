import 'dart:developer';

import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'tron_wallet_addresses.g.dart';

class TronWalletAddresses = TronWalletAddressesBase with _$TronWalletAddresses;

abstract class TronWalletAddressesBase extends WalletAddresses with Store {
  TronWalletAddressesBase(WalletInfo walletInfo)
      : address = '',
        super(walletInfo);

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

  @override
  PaymentURI getPaymentUri(String amount) => TronURI(amount: amount, address: address);
}
