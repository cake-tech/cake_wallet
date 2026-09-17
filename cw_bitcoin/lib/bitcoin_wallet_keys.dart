class BitcoinWalletKeys {
  const BitcoinWalletKeys({
    required this.wif,
    required this.privateKey,
    required this.publicKey,
    required this.xpub,
    this.masterFingerprint = '',
  });

  final String wif;
  final String privateKey;
  final String publicKey;
  final String xpub;
  final String masterFingerprint;

  Map<String, String> toJson() => {
        'wif': wif,
        'privateKey': privateKey,
        'publicKey': publicKey,
        'xpub': xpub,
        'masterFingerprint': masterFingerprint,
      };
}
