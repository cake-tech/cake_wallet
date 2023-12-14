import 'package:cw_core/wallet_addresses.dart';

class NewZanoWalletAddresses extends WalletAddresses {
  @override
  String address;

  NewZanoWalletAddresses(super.walletInfo): address = "";

  @override
  Future<void> init() async {
    print("NewZanoWalletAddresses init");
  }

  @override
  Future<void> updateAddressesInBox() async {
    print("NewZanoWalletAddresses updateAddressesInBox");
  }

}