import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class SolanaNewWalletCredentials extends WalletCredentials {
  SolanaNewWalletCredentials({required String name, WalletInfo? walletInfo})
      : super(name: name, walletInfo: walletInfo);
}

class SolanaRestoreWalletFromSeedCredentials extends WalletCredentials {
  SolanaRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required this.mnemonic,
      WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String mnemonic;
}

class SolanaRestoreWalletFromPrivateKey extends WalletCredentials {
  SolanaRestoreWalletFromPrivateKey(
      {required String name,
      required String password,
      required this.privateKey,
      WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String privateKey;
}
