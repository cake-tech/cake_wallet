import 'package:cw_core/wallet_credentials.dart';

class XelisNewWalletCredentials extends WalletCredentials {
  XelisNewWalletCredentials(
      {required String name, required String password})
      : super(name: name, password: password);
}

class XelisRestoreWalletFromSeedCredentials extends WalletCredentials {
  XelisRestoreWalletFromSeedCredentials(
      {required String name, required this.mnemonic, int height = 0, required String password})
      : super(name: name, password: password, height: height);

  final String mnemonic;
}