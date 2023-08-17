class ChainKeyModel {
  final List<String> chains;
  final String privateKey;
  final String publicKey;

  ChainKeyModel({
    required this.chains,
    required this.privateKey,
    required this.publicKey,
  });

  @override
  String toString() {
    return 'ChainKeyModel(chains: $chains, privateKey: $privateKey, publicKey: $publicKey)';
  }
}
