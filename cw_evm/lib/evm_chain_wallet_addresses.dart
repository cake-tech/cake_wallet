import 'dart:developer';

import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'evm_chain_wallet_addresses.g.dart';

class EVMChainWalletAddresses = EVMChainWalletAddressesBase with _$EVMChainWalletAddresses;

abstract class EVMChainWalletAddressesBase extends WalletAddresses with Store {
  EVMChainWalletAddressesBase(WalletInfo walletInfo, this.chainId)
      : address = '',
        super(walletInfo);

  final int chainId;

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
  PaymentURI getPaymentUri(String amount) {
    switch (chainId) {
      case 8453:
        return BaseURI(amount: amount, address: address);
      case 137:
        return PolygonURI(amount: amount, address: address);
      default:
        return EthereumURI(amount: amount, address: address);
    }
  }
}
