import "package:cake_wallet/wallet_types.g.dart";
import "package:cw_core/wallet_type.dart";

/// Knobs the suites read, either compile time defaults or --dart-define overrides.
class TestConfig {
  static final List<int> pin = [0, 8, 0, 1];

  static const bool isCIBuild = bool.fromEnvironment("CI_BUILD");

  static const String _walletTypesOverride = String.fromEnvironment("TEST_WALLET_TYPES");

  // Solana and ethereum cover the cheap key-derivation chains, bitcoin covers the electrum
  // family and monero covers the native-library chains.
  static final List<WalletType> _representativeWalletTypes = [
    WalletType.solana,
    WalletType.ethereum,
    WalletType.bitcoin,
    WalletType.monero,
  ];

  /// Resolves the wallet types a suite should loop over.
  ///
  /// Defaults to the representative set, `--dart-define=TEST_WALLET_TYPES=all` runs every
  /// available type and a comma separated list of type names runs just those.
  static List<WalletType> get walletTypesUnderTest {
    if (_walletTypesOverride == "all") {
      return availableWalletTypes;
    }

    if (_walletTypesOverride.isNotEmpty) {
      return _walletTypesOverride
          .split(",")
          .map((name) => WalletType.values.byName(name.trim()))
          .where(availableWalletTypes.contains)
          .toList();
    }

    return _representativeWalletTypes.where(availableWalletTypes.contains).toList();
  }
}
