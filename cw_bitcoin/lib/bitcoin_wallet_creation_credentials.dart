import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class BitcoinNewWalletCredentials extends WalletCredentials {
  BitcoinNewWalletCredentials({String name, WalletInfo walletInfo})
      : super(name: name, walletInfo: walletInfo);
}

class BitcoinRestoreWalletFromSeedCredentials extends WalletCredentials {
  BitcoinRestoreWalletFromSeedCredentials(
      {String name, String password, this.mnemonic, WalletInfo walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String mnemonic;
}

class BitcoinRestoreWalletFromWIFCredentials extends WalletCredentials {
  BitcoinRestoreWalletFromWIFCredentials(
      {String name, String password, this.wif, WalletInfo walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String wif;
}
