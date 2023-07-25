class NanoWalletKeys {
  const NanoWalletKeys({
    required this.mnemonic,
    required this.privateKey,
    required this.derivationType,
  });

  final String privateKey;
  final String derivationType;
  final String mnemonic;
}
