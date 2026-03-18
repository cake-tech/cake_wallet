import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class StarknetNewWalletCredentials extends WalletCredentials {
  StarknetNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    this.mnemonic,
    String? passphrase,
  }) : super(
          name: name,
          walletInfo: walletInfo,
          password: password,
          passphrase: passphrase,
        );
  final String? mnemonic;
}

class StarknetRestoreWalletFromSeedCredentials extends WalletCredentials {
  StarknetRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required this.mnemonic,
    WalletInfo? walletInfo,
    String? passphrase,
  }) : super(
          name: name,
          password: password,
          walletInfo: walletInfo,
          passphrase: passphrase,
        );

  final String mnemonic;
}

class StarknetRestoreWalletFromPrivateKey extends WalletCredentials {
  StarknetRestoreWalletFromPrivateKey({
    required String name,
    required String password,
    required this.privateKey,
    WalletInfo? walletInfo,
  }) : super(name: name, password: password, walletInfo: walletInfo);

  final String privateKey;
}
