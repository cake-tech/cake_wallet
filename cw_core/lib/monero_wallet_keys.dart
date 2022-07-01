class MoneroWalletKeys {
  const MoneroWalletKeys(
      {this.privateSpendKey,
        this.privateViewKey,
        this.publicSpendKey,
        this.publicViewKey});

  final String? publicViewKey;
  final String? privateViewKey;
  final String? publicSpendKey;
  final String? privateSpendKey;
}