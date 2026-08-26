import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/entities/default_settings_migration.dart"
    show nanoDefaultPowNodeUri, publicBitcoinTestnetElectrumUri;
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cake_wallet/zcash/zcash_network_type.dart";
import "package:collection/collection.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/node.dart";
import "package:cw_core/wallet_base.dart";
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

  Future<void> resetBalanceCards() async {
    final wallet = _appStore.wallet;
    if (wallet == null) {
      return;
    }

    await BalanceCardStyleSettings.deleteByWalletInfoId(
      wallet.walletInfo.internalId,
    );
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
    await _resetCurrentNodesToDefault(wallet);

    wallet.walletInfo
      ..showCombinedBalance = true
      ..favoriteTokenAddress = null;
    await wallet.walletInfo.save();

    switch (wallet.type) {
      case WalletType.bitcoin:
        await bitcoin!.setAddressType(
          wallet,
          bitcoin!.getOptionToType(bitcoin!.getBitcoinSegwitPageOption()),
        );
        if (bitcoin!.getScanningActive(wallet)) {
          await bitcoin!.setScanningActive(wallet, false);
        }
        bitcoin!.updateUseLightning(
          wallet,
          !wallet.isHardwareWallet && (wallet.seed?.isNotEmpty ?? false),
        );
        await bitcoin!.setIsAlwaysScanningSP(wallet, false);
        bitcoin!.updatePayjoinState(wallet, settingsStore.usePayjoin);
        break;
      case WalletType.litecoin:
        await bitcoin!.setAddressType(
          wallet,
          bitcoin!.getOptionToType(bitcoin!.getBitcoinSegwitPageOption()),
        );
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
      case WalletType.zcash:
        await zcash!.setAddressType(
          wallet,
          zcash!.getOptionToType(zcash!.getDefaultReceivePageOption()),
        );
        break;
      case WalletType.monero:
      case WalletType.none:
      case WalletType.haven:
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.bitcoinCash:
      case WalletType.solana:
      case WalletType.wownero:
      case WalletType.zano:
      case WalletType.decred:
      case WalletType.dogecoin:
        break;
    }
  }

  Future<void> _resetCurrentNodesToDefault(WalletBase wallet) async {
    final walletType = wallet.type;

    if (walletType == WalletType.zcash &&
        ZcashNetworkType.isDevNetwork(wallet.walletInfo.network)) {
      return;
    }

    final node = walletType == WalletType.bitcoin && wallet.isTestnet
        ? (await Node.getAllForWalletType(walletType)).firstWhereOrNull(
            (node) => node.uriRaw == publicBitcoinTestnetElectrumUri,
          )
        : await Node.getDefaultForWalletType(walletType);

    if (node != null) {
      if (isEVMCompatibleChain(walletType)) {
        final defaultChainId = evm!.getChainIdByWalletType(walletType);

        // Switch first, as node updates reconnect the active wallet.
        if (evm!.getSelectedChainId(wallet) != defaultChainId) {
          await evm!.selectChain(wallet, defaultChainId, node: node);
        }
      }

      _appStore.settingsStore.nodes[walletType] = node;
    }

    if (walletType == WalletType.nano) {
      final powNode = await Node.getDefaultPowForWalletType(walletType) ??
          (await Node.getAllForWalletTypePow(walletType)).firstWhereOrNull(
            (node) => node.uriRaw == nanoDefaultPowNodeUri,
          );

      if (powNode != null) {
        _appStore.settingsStore.powNodes[walletType] = powNode;
      }
    }
  }
}
