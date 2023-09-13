import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class BitcoinNewWalletCredentials extends WalletCredentials {
  BitcoinNewWalletCredentials({required String name, WalletInfo? walletInfo})
      : super(name: name, walletInfo: walletInfo);
}

class BitcoinRestoreWalletFromSeedCredentials extends WalletCredentials {
  BitcoinRestoreWalletFromSeedCredentials(
      {required String name, required String password, required this.mnemonic, WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String mnemonic;
}

class BitcoinRestoreWalletFromWIFCredentials extends WalletCredentials {
  BitcoinRestoreWalletFromWIFCredentials(
      {required String name, required String password, required this.wif, WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String wif;
}