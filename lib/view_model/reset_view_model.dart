import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/trade_monitor.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/entities/default_settings_migration.dart"
    show nanoDefaultPowNodeUri, publicBitcoinTestnetElectrumUri;
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/utils/tor.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cake_wallet/zcash/zcash_network_type.dart";
import "package:collection/collection.dart";
import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/node.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/widgets.dart";

class ResetViewModel {
  ResetViewModel(this._appStore, this._tradeMonitor);

  final AppStore _appStore;
  final TradeMonitor _tradeMonitor;

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
    final wasBuiltinTorEnabled = settingsStore.currentBuiltinTor;

    if (wallet.type == WalletType.litecoin) {
      await bitcoin!.setMwebEnabled(wallet, SettingsStoreBase.defaultMwebAlwaysScan);
      settingsStore.mwebAlwaysScan = SettingsStoreBase.defaultMwebAlwaysScan;

      await bitcoin!.setMwebNodeUri(wallet, SettingsStoreBase.defaultMwebNodeUri);
      settingsStore.mwebNodeUri = SettingsStoreBase.defaultMwebNodeUri;
    }

    settingsStore.resetStoreOnlySettingsToDefault(wallet.type);

    settingsStore.autoGenerateSubaddressStatus =
        SettingsStoreBase.defaultAutoGenerateSubaddressStatus;
    wallet.isEnabledAutoGenerateSubaddress =
        settingsStore.autoGenerateSubaddressStatus != AutoGenerateSubaddressStatus.disabled;

    settingsStore.currentBuiltinTor = SettingsStoreBase.defaultBuiltinTor;
    await ensureTorStopped(context: null);
    await _resetCurrentNodesToDefault(wallet, reconnect: wasBuiltinTorEnabled);

    settingsStore.exchangeStatus = SettingsStoreBase.defaultExchangeStatus;
    settingsStore.disableAutomaticExchangeStatusUpdates =
        SettingsStoreBase.defaultDisableAutomaticExchangeStatusUpdates;
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _tradeMonitor.resumeTradeMonitoring();
    }

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
        settingsStore.usePayjoin = SettingsStoreBase.defaultUsePayjoin;
        bitcoin!.updatePayjoinState(wallet, settingsStore.usePayjoin);
        break;
      case WalletType.litecoin:
        await bitcoin!.setAddressType(
          wallet,
          bitcoin!.getOptionToType(bitcoin!.getBitcoinSegwitPageOption()),
        );
        break;
      case WalletType.ethereum:
        settingsStore.useEtherscan = SettingsStoreBase.defaultUseEtherscan;
        evm!.updateScanProviderUsageState(wallet, settingsStore.useEtherscan);
        break;
      case WalletType.polygon:
        settingsStore.usePolygonScan = SettingsStoreBase.defaultUsePolygonScan;
        evm!.updateScanProviderUsageState(wallet, settingsStore.usePolygonScan);
        break;
      case WalletType.base:
        settingsStore.useBaseScan = SettingsStoreBase.defaultUseBaseScan;
        evm!.updateScanProviderUsageState(wallet, settingsStore.useBaseScan);
        break;
      case WalletType.arbitrum:
        settingsStore.useArbiScan = SettingsStoreBase.defaultUseArbiScan;
        evm!.updateScanProviderUsageState(wallet, settingsStore.useArbiScan);
        break;
      case WalletType.bsc:
        settingsStore.useBscScan = SettingsStoreBase.defaultUseBscScan;
        evm!.updateScanProviderUsageState(wallet, settingsStore.useBscScan);
        break;
      case WalletType.tron:
        settingsStore.useTronGrid = SettingsStoreBase.defaultUseTronGrid;
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

  Future<void> _resetCurrentNodesToDefault(WalletBase wallet, {required bool reconnect}) async {
    final settingsStore = _appStore.settingsStore;
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
          reconnect = false;
        }
      }

      if (settingsStore.nodes[walletType] != node) {
        settingsStore.nodes[walletType] = node;
        reconnect = false;
      }
    }

    // reconnect after disabling Tor even if the node hasn't changed.
    if (reconnect) {
      final chainId = isEVMCompatibleChain(walletType) ? evm!.getSelectedChainId(wallet) : null;
      await wallet.connectToNode(
        node: settingsStore.getCurrentNode(walletType, chainId: chainId),
      );
    }

    if (walletType == WalletType.nano) {
      final powNode = await Node.getDefaultPowForWalletType(walletType) ??
          (await Node.getAllForWalletTypePow(walletType)).firstWhereOrNull(
            (node) => node.uriRaw == nanoDefaultPowNodeUri,
          );

      if (powNode != null) {
        settingsStore.powNodes[walletType] = powNode;
      }
    }
  }
}
