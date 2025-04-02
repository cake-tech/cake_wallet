class XelisNewWalletCredentials extends WalletCredentials {
  XelisNewWalletCredentials(
      {required String name, required this.language, this.passphrase, String? password})
      : super(name: name, password: password);

  final String language;
  final String? passphrase;
}

class XelisRestoreWalletFromSeedCredentials extends WalletCredentials {
  XelisRestoreWalletFromSeedCredentials(
      {required String name, required this.mnemonic, required this.passphrase, int height = 0, String? password})
      : super(name: name, password: password, height: height);

  final String mnemonic;
  final String passphrase;
}