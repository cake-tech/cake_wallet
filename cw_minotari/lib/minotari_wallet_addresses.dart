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
    // Minotari wallets have a single address derived from keys
    // The address will be set when the wallet is initialized
  }

  void setAddress(String newAddress) {
    address = newAddress;
  }
}
