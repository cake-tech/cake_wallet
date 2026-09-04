import "package:cw_core/wallet_credentials.dart";

class BitcoinCashNewWalletCredentials extends WalletCredentials {
  BitcoinCashNewWalletCredentials({
    required super.name,
    super.walletInfo,
    super.password,
    super.passphrase,
    this.mnemonic,
  });

  final String? mnemonic;
}

class BitcoinCashRestoreWalletFromSeedCredentials extends WalletCredentials {
  BitcoinCashRestoreWalletFromSeedCredentials({
    required super.name,
    required String super.password,
    required this.mnemonic,
    super.walletInfo,
    super.passphrase,
  });

  final String mnemonic;
}

class BitcoinCashRestoreWalletFromWIFCredentials extends WalletCredentials {
  BitcoinCashRestoreWalletFromWIFCredentials({
    required super.name,
    required String super.password,
    required this.wif,
    super.walletInfo,
  });

  final String wif;
}
