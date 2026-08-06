import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/wallet_types.g.dart";
import "package:cw_core/wallet_type.dart";

import "funded_wallets.dart";

class TestWallets {
  static List<WalletType> get fundedWalletTypes =>
      availableWalletTypes.where((type) => fundedSeedFor(type).isNotEmpty).toList();

  static List<String> fundedSeedsFor(WalletType type) =>
      (fundedWalletSeeds[type.name] ?? []).where((seed) => seed.trim().isNotEmpty).toList();

  static String fundedSeedFor(WalletType type) {
    final seeds = fundedSeedsFor(type);

    return seeds.isEmpty ? "" : seeds.first;
  }

  static String seedFor(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return secrets.moneroTestWalletSeeds;
      case WalletType.bitcoin:
        return secrets.bitcoinTestWalletSeeds;
      case WalletType.ethereum:
        return secrets.ethereumTestWalletSeeds;
      case WalletType.litecoin:
        return secrets.litecoinTestWalletSeeds;
      case WalletType.bitcoinCash:
        return secrets.bitcoinCashTestWalletSeeds;
      case WalletType.polygon:
        return secrets.polygonTestWalletSeeds;
      case WalletType.solana:
        return secrets.solanaTestWalletSeeds;
      case WalletType.base:
        return secrets.baseTestWalletSeeds;
      case WalletType.arbitrum:
        return secrets.arbitrumTestWalletSeeds;
      case WalletType.bsc:
        return secrets.bscTestWalletSeeds;
      case WalletType.tron:
        return secrets.tronTestWalletSeeds;
      case WalletType.nano:
        return secrets.nanoTestWalletSeeds;
      case WalletType.wownero:
        return secrets.wowneroTestWalletSeeds;
      case WalletType.zano:
        return secrets.zanoTestWalletSeeds;
      case WalletType.decred:
        return secrets.decredTestWalletSeeds;
      case WalletType.dogecoin:
        return secrets.dogeTestWalletSeeds;
      case WalletType.zcash:
        return secrets.zcashTestWalletSeeds;
      case WalletType.none:
      case WalletType.haven:
      case WalletType.banano:
        throw Exception("No test wallet seed available for ${type.name}");
    }
  }

  static String receiveAddressFor(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return secrets.moneroTestWalletReceiveAddress;
      case WalletType.bitcoin:
        return secrets.bitcoinTestWalletReceiveAddress;
      case WalletType.ethereum:
        return secrets.ethereumTestWalletReceiveAddress;
      case WalletType.litecoin:
        return secrets.litecoinTestWalletReceiveAddress;
      case WalletType.bitcoinCash:
        return secrets.bitcoinCashTestWalletReceiveAddress;
      case WalletType.polygon:
        return secrets.polygonTestWalletReceiveAddress;
      case WalletType.base:
        return secrets.baseTestWalletReceiveAddress;
      case WalletType.arbitrum:
        return secrets.arbitrumTestWalletReceiveAddress;
      case WalletType.bsc:
        return secrets.bscTestWalletReceiveAddress;
      case WalletType.solana:
        return secrets.solanaTestWalletReceiveAddress;
      case WalletType.tron:
        return secrets.tronTestWalletReceiveAddress;
      case WalletType.nano:
        return secrets.nanoTestWalletReceiveAddress;
      case WalletType.wownero:
        return secrets.wowneroTestWalletReceiveAddress;
      default:
        return "";
    }
  }

  // Only the legacy 25 word monero seed needs a restore height.
  static String get moneroRestoreBlockHeight => secrets.moneroTestWalletBlockHeight;
}
