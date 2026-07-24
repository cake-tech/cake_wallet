/// Zcash network indices passed from lib/ into cw_zcash.
abstract final class ZcashNetworkType {
  static const int mainnet = 0;
  static const int testnet = 1;
  static const int regtest = 2;

  static const List<int> values = [mainnet, testnet, regtest];

  static String label(final int network) => switch (network) {
        testnet => 'Testnet',
        regtest => 'Regtest',
        _ => 'Mainnet',
      };

  static bool isDevNetwork(final String? network) =>
      network?.toLowerCase() == 'testnet' || network?.toLowerCase() == 'regtest';
}
