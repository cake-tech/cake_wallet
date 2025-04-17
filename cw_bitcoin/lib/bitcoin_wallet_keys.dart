class BitcoinWalletKeys {
  const BitcoinWalletKeys({required this.wif, required this.privateKey, required this.publicKey});

  final String wif;
  final String privateKey;
  final String publicKey;

  @override
  String toString() {
    return 'BitcoinWalletKeys(wif: $wif, privateKey: $privateKey, publicKey: $publicKey)';
  }
}