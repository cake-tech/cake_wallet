import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class EthereumNewWalletCredentials extends WalletCredentials {
  EthereumNewWalletCredentials({required String name, WalletInfo? walletInfo})
      : super(name: name, walletInfo: walletInfo);
}

class EthereumRestoreWalletFromSeedCredentials extends WalletCredentials {
  EthereumRestoreWalletFromSeedCredentials(
      {required String name, required String password, required this.mnemonic, WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String mnemonic;
}

class EthereumRestoreWalletFromWIFCredentials extends WalletCredentials {
  EthereumRestoreWalletFromWIFCredentials(
      {required String name, required String password, required this.wif, WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String wif;
}
