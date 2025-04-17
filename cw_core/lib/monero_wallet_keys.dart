class MoneroWalletKeys {
  const MoneroWalletKeys(
      {required this.primaryAddress,
        required this.privateSpendKey,
        required this.privateViewKey,
        required this.publicSpendKey,
        required this.publicViewKey,
        required this.passphrase});

  final String primaryAddress;
  final String publicViewKey;
  final String privateViewKey;
  final String publicSpendKey;
  final String privateSpendKey;
  final String passphrase;

  @override
  String toString() {
    return 'MoneroWalletKeys(primaryAddress: $primaryAddress, publicViewKey: $publicViewKey, privateViewKey: $privateViewKey, publicSpendKey: $publicSpendKey, privateSpendKey: $privateSpendKey, passphrase: $passphrase)';
  }
}