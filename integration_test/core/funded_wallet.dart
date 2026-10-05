class FundedWallet {
  const FundedWallet({required this.seed, this.passphrase = ""});

  final String seed;
  final String passphrase;
}
