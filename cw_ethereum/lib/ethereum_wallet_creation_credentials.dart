import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class EthereumNewWalletCredentials extends WalletCredentials {
  EthereumNewWalletCredentials({required String name, WalletInfo? walletInfo, String? password})
      : super(name: name, walletInfo: walletInfo, password: password);
}

class EthereumRestoreWalletFromSeedCredentials extends WalletCredentials {
  EthereumRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required this.mnemonic,
      WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String mnemonic;
}

class EthereumRestoreWalletFromPrivateKey extends WalletCredentials {
  EthereumRestoreWalletFromPrivateKey(
      {required String name,
      required String password,
      required this.privateKey,
      WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String privateKey;
}
