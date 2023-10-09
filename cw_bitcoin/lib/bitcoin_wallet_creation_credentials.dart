import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class BitcoinNewWalletCredentials extends WalletCredentials {
  BitcoinNewWalletCredentials(
      {required String name, WalletInfo? walletInfo, this.derivationType, this.derivationPath})
      : super(name: name, walletInfo: walletInfo);
  DerivationType? derivationType;
  String? derivationPath;
}

class BitcoinRestoreWalletFromSeedCredentials extends WalletCredentials {
  BitcoinRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required this.mnemonic,
    WalletInfo? walletInfo,
    DerivationType? derivationType,
    String? derivationPath,
  }) : super(
            name: name,
            password: password,
            walletInfo: walletInfo,
            derivationInfo: DerivationInfo(
              derivationType: derivationType,
              derivationPath: derivationPath,
            ));

  final String mnemonic;
}

class BitcoinRestoreWalletFromWIFCredentials extends WalletCredentials {
  BitcoinRestoreWalletFromWIFCredentials(
      {required String name, required String password, required this.wif, WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String wif;
}
