class NanoWalletKeys {
  const NanoWalletKeys({required this.seedKey});

  final String seedKey;

  @override
  String toString() {
    return 'NanoWalletKeys(seedKey: $seedKey)';
  }
}
