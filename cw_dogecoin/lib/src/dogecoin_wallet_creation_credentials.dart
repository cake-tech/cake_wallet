import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class DogeCoinNewWalletCredentials extends WalletCredentials {
  DogeCoinNewWalletCredentials({
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

class DogeCoinRestoreWalletFromSeedCredentials extends WalletCredentials {
  DogeCoinRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required this.mnemonic,
    WalletInfo? walletInfo,
    String? passphrase,
  }) : super(name: name, password: password, walletInfo: walletInfo, passphrase: passphrase);

  final String mnemonic;
}

class DogeCoinRestoreWalletFromWIFCredentials extends WalletCredentials {
  DogeCoinRestoreWalletFromWIFCredentials(
      {required String name, required String password, required this.wif, WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String wif;
}
