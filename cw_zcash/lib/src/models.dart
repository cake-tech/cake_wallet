import 'package:cw_core/wallet_credentials.dart';

class ZcashNewWalletCredentials extends WalletCredentials {
  ZcashNewWalletCredentials({
    required final String name,
    final String? password,
    required final String? passphrase,
    final String? mnemonic,
    final int? seedPhraseLength,
  }) : super(name: name, password: password, passphrase: passphrase, seedPhraseLength: seedPhraseLength) {
    this.mnemonic = mnemonic;
  }

  String? mnemonic;
}

class ZcashFromSeedWalletCredentials extends WalletCredentials {
  ZcashFromSeedWalletCredentials({
    required final String name,
    final String? password,
    required final String? passphrase,
    required this.seed,
  }) : super(name: name, password: password, passphrase: passphrase);
  final String? seed;
}

class ZcashFromKeysWalletCredentials extends WalletCredentials {
  ZcashFromKeysWalletCredentials({
    required final String name,
    final String? password,
    required final String? passphrase,
    required this.privateKey,
  }) : super(name: name, password: password, passphrase: passphrase);
  final String? privateKey;
}
