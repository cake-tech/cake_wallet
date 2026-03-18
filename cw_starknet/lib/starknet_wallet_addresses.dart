import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:mobx/mobx.dart';

part 'starknet_wallet_addresses.g.dart';

class StarknetWalletAddresses = StarknetWalletAddressesBase with _$StarknetWalletAddresses;

abstract class StarknetWalletAddressesBase extends WalletAddresses with Store {
  StarknetWalletAddressesBase(WalletInfo walletInfo)
      : address = '',
        super(walletInfo);

  @override
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
      printV(e.toString());
    }
  }

  @override
  PaymentURI getPaymentUri(String amount) => StarknetURI(amount: amount, address: address);
}
