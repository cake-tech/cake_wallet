class ZanoWalletKeys {
  const ZanoWalletKeys(
      {required this.privateSpendKey,
        required this.privateViewKey,
        required this.publicSpendKey,
        required this.publicViewKey});

  final String publicViewKey;
  final String privateViewKey;
  final String publicSpendKey;
  final String privateSpendKey;

  @override
  String toString() {
    return 'ZanoWalletKeys(publicViewKey: $publicViewKey, privateViewKey: $privateViewKey, publicSpendKey: $publicSpendKey, privateSpendKey: $privateSpendKey)';
  }
}