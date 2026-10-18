enum ZcashNetwork {
  mainnet,
  testnet,
  regtest;

  /// NU6.3 / Ironwood activation height on zkool regtest (see zkool2/misc/zebra.toml).
  static const int regtestNu63Height = 250;

  String get value => name;

  String get label => switch (this) {
        ZcashNetwork.mainnet => 'Mainnet',
        ZcashNetwork.testnet => 'Testnet',
        ZcashNetwork.regtest => 'Regtest',
      };

  String get dbFileName => switch (this) {
        ZcashNetwork.mainnet => 'zec.v2.db',
        ZcashNetwork.testnet => 'zec.testnet.v2.db',
        ZcashNetwork.regtest => 'zec.regtest.v2.db',
      };

  /// Default lightwalletd endpoint for dev networks.
  String get defaultNodeUri => switch (this) {
        ZcashNetwork.mainnet => 'zec.rocks:443',
        ZcashNetwork.testnet => 'testnet.lightwalletd.com:9067',
        ZcashNetwork.regtest => '10.0.2.2:9067', // 10.0.2.2 - AVD host bridge
      };

  bool get useSsl => this == ZcashNetwork.mainnet;

  static ZcashNetwork fromName(final String? name) => switch (name) {
        'testnet' => ZcashNetwork.testnet,
        'regtest' => ZcashNetwork.regtest,
        _ => ZcashNetwork.mainnet,
      };

  static ZcashNetwork fromIndex(final int index) => switch (index) {
        1 => ZcashNetwork.testnet,
        2 => ZcashNetwork.regtest,
        _ => ZcashNetwork.mainnet,
      };

  int get networkIndex => switch (this) {
        ZcashNetwork.testnet => 1,
        ZcashNetwork.regtest => 2,
        ZcashNetwork.mainnet => 0,
      };
}
