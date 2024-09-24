import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class TronNewWalletCredentials extends WalletCredentials {
  TronNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    this.mnemonic,
    String? parentAddress,
  }) : super(
          name: name,
          walletInfo: walletInfo,
          password: password,
          parentAddress: parentAddress,
        );

  final String? mnemonic;
}

class TronRestoreWalletFromSeedCredentials extends WalletCredentials {
  TronRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required this.mnemonic,
      WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String mnemonic;
}

class TronRestoreWalletFromPrivateKey extends WalletCredentials {
  TronRestoreWalletFromPrivateKey(
      {required String name,
      required String password,
      required this.privateKey,
      WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String privateKey;
}
