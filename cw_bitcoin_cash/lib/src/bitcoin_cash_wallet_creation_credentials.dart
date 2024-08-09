import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class BitcoinCashNewWalletCredentials extends WalletCredentials {
  BitcoinCashNewWalletCredentials({required String name, WalletInfo? walletInfo, String? password})
      : super(name: name, walletInfo: walletInfo, password: password);
}

class BitcoinCashRestoreWalletFromSeedCredentials extends WalletCredentials {
  BitcoinCashRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required this.mnemonic,
      WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String mnemonic;
}

class BitcoinCashRestoreWalletFromWIFCredentials extends WalletCredentials {
  BitcoinCashRestoreWalletFromWIFCredentials(
      {required String name, required String password, required this.wif, WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String wif;
}
