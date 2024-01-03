import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
class PolygonNewWalletCredentials extends WalletCredentials {
  PolygonNewWalletCredentials({required String name, WalletInfo? walletInfo})
      : super(name: name, walletInfo: walletInfo);
}

class PolygonRestoreWalletFromSeedCredentials extends WalletCredentials {
  PolygonRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required this.mnemonic,
      WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String mnemonic;
}

class PolygonRestoreWalletFromPrivateKey extends WalletCredentials {
  PolygonRestoreWalletFromPrivateKey(
      {required String name,
      required String password,
      required this.privateKey,
      WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String privateKey;
}
