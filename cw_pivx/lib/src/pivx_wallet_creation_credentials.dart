import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class PivxNewWalletCredentials extends WalletCredentials {
  PivxNewWalletCredentials({
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

class PivxRestoreWalletFromSeedCredentials extends WalletCredentials {
  PivxRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required this.mnemonic,
    WalletInfo? walletInfo,
    String? passphrase,
    int? height,
  }) : super(
          name: name,
          password: password,
          walletInfo: walletInfo,
          passphrase: passphrase,
          height: height,
        );

  final String mnemonic;
}

class PivxRestoreWalletFromWIFCredentials extends WalletCredentials {
  PivxRestoreWalletFromWIFCredentials({
    required String name,
    required String password,
    required this.wif,
    WalletInfo? walletInfo,
  }) : super(
          name: name,
          password: password,
          walletInfo: walletInfo,
        );

  final String wif;
}
