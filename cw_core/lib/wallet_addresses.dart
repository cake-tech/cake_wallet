import 'package:cw_core/wallet_info.dart';

abstract class WalletAddresses {
  WalletAddresses(this.walletInfo)
    : addressesMap = {};

  final WalletInfo walletInfo;

  String get address;

  set address(String address);

  Map<String, String> addressesMap;

  Future<void> init();

  Future<void> updateAddressesInBox();

  Future<void> saveAddressesInBox() async {
    try {
      walletInfo.address = address;
      walletInfo.addresses = addressesMap;

      if (walletInfo.isInBox) {
        await walletInfo.save();
      }
    } catch (e) {
      print(e.toString());
    }
  }
}