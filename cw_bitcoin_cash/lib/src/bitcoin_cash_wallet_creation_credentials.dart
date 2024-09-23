import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class BitcoinCashNewWalletCredentials extends WalletCredentials {
  BitcoinCashNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
    this.mnemonic,
    String? parentAddress,
  }) : super(
          name: name,
          walletInfo: walletInfo,
          password: password,
          passphrase: passphrase,
          parentAddress: parentAddress
        );
  final String? mnemonic;
}

class BitcoinCashRestoreWalletFromSeedCredentials extends WalletCredentials {
  BitcoinCashRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required this.mnemonic,
    WalletInfo? walletInfo,
    String? passphrase,
  }) : super(name: name, password: password, walletInfo: walletInfo, passphrase: passphrase);

  final String mnemonic;
}

class BitcoinCashRestoreWalletFromWIFCredentials extends WalletCredentials {
  BitcoinCashRestoreWalletFromWIFCredentials(
      {required String name, required String password, required this.wif, WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String wif;
}
