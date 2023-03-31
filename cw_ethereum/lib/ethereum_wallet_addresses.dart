import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'ethereum_wallet_addresses.g.dart';

class EthereumWalletAddresses = EthereumWalletAddressesBase with _$EthereumWalletAddresses;

abstract class EthereumWalletAddressesBase extends WalletAddresses with Store {
  EthereumWalletAddressesBase(WalletInfo walletInfo)
      : address = '',
        super(walletInfo);

  @override
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
      print(e.toString());
    }
  }
}
