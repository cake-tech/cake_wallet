import 'package:cake_wallet/core/wallet_credentials.dart';

class BitcoinNewWalletCredentials extends WalletCredentials {
  BitcoinNewWalletCredentials({String name}) : super(name: name);
}

class BitcoinRestoreWalletFromSeedCredentials extends WalletCredentials {
  BitcoinRestoreWalletFromSeedCredentials(
      {String name, String password, this.mnemonic})
      : super(name: name, password: password);

  final String mnemonic;
}

class BitcoinRestoreWalletFromWIFCredentials extends WalletCredentials {
  BitcoinRestoreWalletFromWIFCredentials(
      {String name, String password, this.wif})
      : super(name: name, password: password);

  final String wif;
}
