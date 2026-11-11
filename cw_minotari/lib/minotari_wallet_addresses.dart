import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'minotari_wallet_addresses.g.dart';

class MinotariWalletAddresses = MinotariWalletAddressesBase with _$MinotariWalletAddresses;

abstract class MinotariWalletAddressesBase extends WalletAddresses with Store {
  MinotariWalletAddressesBase(WalletInfo walletInfo)
      : address = '',
        super(walletInfo);

  @override
  @observable
  String address;

  @override
  Future<void> init() async {
    await updateAddressesInBox();
  }

  @override
  Future<void> updateAddressesInBox() async {
    if (address.isEmpty) return;
    addressesMap
      ..clear()
      ..[address] = '';
    await saveAddressesInBox();
  }

  Future<void> setAddress(String newAddress) async {
    address = newAddress;
    await updateAddressesInBox();
  }

  @override
  PaymentURI getPaymentUri(String amount) => MinotariURI(amount: amount, address: address);
}
