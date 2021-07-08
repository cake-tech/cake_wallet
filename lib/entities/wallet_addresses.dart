import 'package:cake_wallet/entities/wallet_addresses_credentials.dart';
import 'package:cake_wallet/entities/wallet_info.dart';

abstract class WalletAddresses {
  WalletAddresses(this.walletInfo) {
    addresses = walletInfo?.addresses ?? {};
  }

  final WalletInfo walletInfo;

  Map<String, String> addresses;

  Future<void> update(WalletAddressesCredentials credentials);

  Future<void> save() async {
    try {
      if (walletInfo == null) {
        return;
      }

      walletInfo.addresses = addresses;

      if (walletInfo.isInBox) {
        await walletInfo.save();
      }
    } catch (e) {
      print(e.toString());
    }
  }
}