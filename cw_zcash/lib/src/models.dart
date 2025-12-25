import 'package:cw_core/wallet_credentials.dart';


class ZcashNewWalletCredentials extends WalletCredentials {
  ZcashNewWalletCredentials({
    required String name,
    String? password,
    required String? passphrase,
    String? mnemonic,
    int? seedPhraseLength,
  }) : super(name: name, password: password, passphrase: passphrase, seedPhraseLength: seedPhraseLength) {
    this.mnemonic = mnemonic;
  }
  
  String? mnemonic;
}

class ZcashFromSeedWalletCredentials extends WalletCredentials {
  ZcashFromSeedWalletCredentials({
    required String name,
    String? password,
    required String? passphrase,
    required this.seed,
  }) : super(name: name, password: password, passphrase: passphrase);
  final String? seed;
}

class ZcashFromKeysWalletCredentials extends WalletCredentials {
  ZcashFromKeysWalletCredentials({
    required String name,
    String? password,
    required String? passphrase,
    required this.privateKey,
  }) : super(name: name, password: password, passphrase: passphrase);
  final String? privateKey;
}