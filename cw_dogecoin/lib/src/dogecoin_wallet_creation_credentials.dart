import "package:cw_core/wallet_credentials.dart";

class DogeCoinNewWalletCredentials extends WalletCredentials {
  DogeCoinNewWalletCredentials({
    required super.name,
    super.walletInfo,
    super.password,
    super.passphrase,
    this.mnemonic,
  });

  final String? mnemonic;
}

class DogeCoinRestoreWalletFromSeedCredentials extends WalletCredentials {
  DogeCoinRestoreWalletFromSeedCredentials({
    required super.name,
    required String super.password,
    required this.mnemonic,
    super.walletInfo,
    super.passphrase,
  });

  final String mnemonic;
}

class DogeCoinRestoreWalletFromWIFCredentials extends WalletCredentials {
  DogeCoinRestoreWalletFromWIFCredentials({
    required super.name,
    required String super.password,
    required this.wif,
    super.walletInfo,
  });

  final String wif;
}
