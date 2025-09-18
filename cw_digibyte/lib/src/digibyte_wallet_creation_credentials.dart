import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class DigibyteNewWalletCredentials extends WalletCredentials {
  DigibyteNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
    this.mnemonic,
  }) : super(
          name: name,
          walletInfo: walletInfo,
          password: password,
          passphrase: passphrase,
        );
  final String? mnemonic;
}

class DigibyteRestoreWalletFromSeedCredentials extends WalletCredentials {
  DigibyteRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required this.mnemonic,
    WalletInfo? walletInfo,
    String? passphrase,
  }) : super(name: name, password: password, walletInfo: walletInfo, passphrase: passphrase);

  final String mnemonic;
}

class DigibyteRestoreWalletFromWIFCredentials extends WalletCredentials {
  DigibyteRestoreWalletFromWIFCredentials(
      {required String name, required String password, required this.wif, WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String wif;
}
