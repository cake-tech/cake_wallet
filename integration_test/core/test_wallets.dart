import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cw_core/wallet_type.dart";

/// The only place tests read wallet secrets from, keeps .secrets.g.dart out of robots and suites.
class TestWallets {
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

  /// Restore block height for the legacy 25 word monero test wallet.
  static String get moneroRestoreBlockHeight => secrets.moneroTestWalletBlockHeight;
}
