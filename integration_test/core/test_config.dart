import "package:cake_wallet/wallet_types.g.dart";
import "package:cw_core/wallet_type.dart";

import "test_wallets.dart";

class TestConfig {
  static final List<int> pin = [0, 8, 0, 1];

  static const bool isCIBuild = bool.fromEnvironment("CI_BUILD");

  static const String _walletTypesOverride = String.fromEnvironment("TEST_WALLET_TYPES");

  static const String _fundsFlows = String.fromEnvironment("FLOWS", defaultValue: "all");

  static const String _fundedChainsOverride = String.fromEnvironment(
    "CHAINS",
    defaultValue: "auto",
  );

  // Tiny real amounts that still clear each chain's dust threshold.
  static const Map<String, String> _fundsSendAmounts = {
    "solana": "0.0001",
    "ethereum": "0.00001",
    "polygon": "0.01",
    "base": "0.00001",
    "arbitrum": "0.00001",
    "bsc": "0.00001",
    "tron": "1",
    "bitcoin": "0.0002",
    "litecoin": "0.001",
    "bitcoinCash": "0.0002",
    "dogecoin": "2",
    "monero": "0.0001",
    "wownero": "0.1",
  };

  static String fundsSendAmountFor(WalletType type) => _fundsSendAmounts[type.name] ?? "0.0001";

  static bool shouldRunFundsFlow(String flow) => _fundsFlows == "all" || _fundsFlows == flow;

  // Moving funds has to be asked for on its own, separately from picking a flow, so nothing
  // spends unless someone deliberately said to.
  static const String _spend = String.fromEnvironment("SPEND", defaultValue: "false");

  static bool shouldSpend(String flow) => _spend == "true" && shouldRunFundsFlow(flow);

  static bool shouldDryRun(String flow) => shouldRunFundsFlow(flow);

  static List<WalletType> get fundedWalletTypesUnderTest {
    if (_fundedChainsOverride == "auto") {
      return TestWallets.fundedWalletTypes;
    }

    return _fundedChainsOverride
        .split(",")
        .map(_walletTypeByName)
        .where((type) => TestWallets.fundedSeedFor(type).isNotEmpty)
        .toList();
  }

  static WalletType _walletTypeByName(String name) {
    final trimmed = name.trim();

    // A typo in the CHAINS dispatch input has to fail with a readable message.
    final type = WalletType.values.where((value) => value.name == trimmed).toList();
    if (type.isEmpty) {
      throw ArgumentError(
        'Unknown wallet type "$trimmed" in CHAINS, '
        "valid names: ${WalletType.values.map((value) => value.name).join(", ")}",
      );
    }

    return type.first;
  }

  // Solana and ethereum cover the cheap key-derivation chains, bitcoin covers the electrum
  // family and monero covers the native-library chains.
  static final List<WalletType> _representativeWalletTypes = [
    WalletType.solana,
    WalletType.ethereum,
    WalletType.bitcoin,
    WalletType.monero,
  ];

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
