class BitcoinWalletKeys {
  const BitcoinWalletKeys({required this.wif, required this.privateKey, required this.publicKey, required this.xpub});

  final String wif;
  final String privateKey;
  final String publicKey;
  final String xpub;

  Map<String, String> toJson() => {
    'wif': wif,
    'privateKey': privateKey,
    'publicKey': publicKey,
    'xpub': xpub
  };
}