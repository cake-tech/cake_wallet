import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cw_core/wallet_type.dart";

class ResetViewModel {
  ResetViewModel(this._appStore);

  final AppStore _appStore;

  bool get hasRescan {
    final wallet = _appStore.wallet;

    return wallet != null &&
        wallet.hasRescan &&
        wallet.type != WalletType.bitcoin &&
        wallet.type != WalletType.litecoin;
  }

  Future<void> resetSettingsToDefault() async {
    final wallet = _appStore.wallet;
    if (wallet == null) {
      return;
    }

    final settingsStore = _appStore.settingsStore;

    if (wallet.type == WalletType.litecoin) {
      await bitcoin!.setMwebEnabled(
        wallet,
        SettingsStoreBase.defaultMwebAlwaysScan,
      );
      await bitcoin!.setMwebNodeUri(
        wallet,
        SettingsStoreBase.defaultMwebNodeUri,
      );
    }

    settingsStore.resetCurrencySettingsToDefault(wallet.type);

    switch (wallet.type) {
      case WalletType.bitcoin:
        bitcoin!.updatePayjoinState(wallet, settingsStore.usePayjoin);
        break;
      case WalletType.ethereum:
        evm!.updateScanProviderUsageState(wallet, settingsStore.useEtherscan);
        break;
      case WalletType.polygon:
        evm!.updateScanProviderUsageState(wallet, settingsStore.usePolygonScan);
        break;
      case WalletType.base:
        evm!.updateScanProviderUsageState(wallet, settingsStore.useBaseScan);
        break;
      case WalletType.arbitrum:
        evm!.updateScanProviderUsageState(wallet, settingsStore.useArbiScan);
        break;
      case WalletType.bsc:
        evm!.updateScanProviderUsageState(wallet, settingsStore.useBscScan);
        break;
      case WalletType.tron:
        tron!.updateTronGridUsageState(wallet, settingsStore.useTronGrid);
        break;
      case WalletType.monero:
      case WalletType.none:
      case WalletType.litecoin:
      case WalletType.haven:
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.bitcoinCash:
      case WalletType.solana:
      case WalletType.wownero:
      case WalletType.zano:
      case WalletType.decred:
      case WalletType.dogecoin:
      case WalletType.zcash:
        break;
    }
  }
}
