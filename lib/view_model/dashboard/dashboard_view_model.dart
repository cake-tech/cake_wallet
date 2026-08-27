import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/address_resolver/yat/yat_store.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/view_model/dashboard/date_section_item.dart';
import "package:cw_core/balance_card_style_settings.dart";
import 'package:cake_wallet/core/trade_monitor.dart';
import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/service_status.dart';
import 'package:cake_wallet/entities/sync_status_display_mode.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/order/order_provider_description.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/store/dashboard/order_filter_store.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/zcash/zcash.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cake_wallet/utils/tor.dart';
import 'package:cake_wallet/wownero/wownero.dart' as wow;
import 'package:cake_wallet/store/anonpay/anonpay_transactions_store.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/store/dashboard/payjoin_transactions_store.dart';
import 'package:cake_wallet/store/dashboard/trade_filter_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/dashboard/transaction_filter_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import "package:cw_core/action_list_item.dart";
import "package:cake_wallet/anonpay/anonpay_invoice_info.dart";
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import "package:cake_wallet/order/order.dart";
import 'package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart';
import "package:cake_wallet/exchange/trade.dart";
import "package:cw_core/transaction_info.dart";
import 'package:cake_wallet/view_model/settings/sync_mode.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/card_design.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/utils/file.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_daemon/flutter_daemon.dart';
import 'package:mobx/mobx.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/evm/evm.dart';

part 'dashboard_view_model.g.dart';

class DashboardViewModel = DashboardViewModelBase with _$DashboardViewModel;

abstract class DashboardViewModelBase with Store {
  DashboardViewModelBase(
      {required this.balanceViewModel,
      required this.tradeMonitor,
      required this.appStore,
      required this.tradeFilterStore,
      required this.orderFilterStore,
      required this.transactionFilterStore,
      required this.settingsStore,
      required this.yatStore,
      required this.sharedPreferences,
      required this.keyService})
      : hasTradeAction = true,
        hasSwapAction = true,
        isShowFirstYatIntroduction = false,
        isShowSecondYatIntroduction = false,
        isShowThirdYatIntroduction = false,
        filterItems = [],
        exchangeFilterItems = [],
        name = appStore.wallet!.name,
        type = appStore.wallet!.type,
        cardDesigns = ObservableList<CardDesign>(),
        cardOrder = ObservableMap<int, int>(),
        wallet = appStore.wallet! {
    name = wallet.name;
    type = wallet.type;
    isShowFirstYatIntroduction = false;
    isShowSecondYatIntroduction = false;
    isShowThirdYatIntroduction = false;
    unawaited(isBackgroundSyncEnabled());
    unawaited(isBatteryOptimizationEnabled());
    unawaited(_loadConstraints());

    loadFilterItems();


    _walletChangeDisposer?.reaction.dispose();
    _walletChangeDisposer = reaction((_) => appStore.wallet, (wallet) {
      _onWalletChange(wallet);
      _checkMweb();
      loadCardDesigns();

      tradeMonitor.stopTradeMonitoring();
      tradeMonitor.monitorActiveTrades(wallet!.id);
    });

    if (hasSilentPayments) {
      silentPaymentsScanningActive = bitcoin!.getScanningActive(wallet);

      reaction((_) => wallet.syncStatus, (SyncStatus syncStatus) {
        silentPaymentsScanningActive = bitcoin!.getScanningActive(wallet);
      });
    }

    loadCardDesigns();

    _checkMweb();
    reaction((_) => settingsStore.mwebAlwaysScan, (bool value) => _checkMweb());


    tradeMonitor.monitorActiveTrades(wallet.id);
  }

  void loadFilterItems() {
    filterItems = [
      // FilterItem(
      //     value: () => transactionFilterStore.displayAll,
      //     caption: S.current.all_transactions,
      //     onChanged: transactionFilterStore.toggleAll),
      FilterItem(
          value: () => transactionFilterStore.displayOutgoing,
          caption: S.current.send,
          onChanged: transactionFilterStore.toggleOutgoing),
      FilterItem(
          value: () => transactionFilterStore.displayIncoming,
          caption: S.current.receive,
          onChanged: transactionFilterStore.toggleIncoming),
      if (appStore.wallet!.type == WalletType.bitcoin)
        FilterItem(
          value: () => transactionFilterStore.displaySilentPayments,
          caption: S.current.silent_payments,
          onChanged: transactionFilterStore.toggleSilentPayments,
        ),
      SwapFilterItem(
          enabledProviders: () => tradeFilterStore.enabledProvidersCount,
          allEnabled: () => tradeFilterStore.displayAllTrades,
          value: () => tradeFilterStore.enabledProvidersCount > 0,
          onChanged: () => tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.all)),
      FilterItem(
          value: () => orderFilterStore.displayCakePay,
          caption: 'Cake Pay',
          onChanged: () => orderFilterStore.toggleDisplayOrder(OrderProviderDescription.cakePay)),
    ];
    exchangeFilterItems = [
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.changeNow,
          value: () => tradeFilterStore.displayChangeNow,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.changeNow)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.sideShift,
          value: () => tradeFilterStore.displaySideShift,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.sideShift)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.simpleSwap,
          value: () => tradeFilterStore.displaySimpleSwap,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.simpleSwap)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.trocador,
          value: () => tradeFilterStore.displayTrocador,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.trocador)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.exolix,
          value: () => tradeFilterStore.displayExolix,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.exolix)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.chainflip,
          value: () => tradeFilterStore.displayChainflip,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.chainflip)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.thorChain,
          value: () => tradeFilterStore.displayThorChain,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.thorChain)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.letsExchange,
          value: () => tradeFilterStore.displayLetsExchange,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.letsExchange)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.stealthEx,
          value: () => tradeFilterStore.displayStealthEx,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.stealthEx)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.xoSwap,
          value: () => tradeFilterStore.displayXOSwap,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.xoSwap)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.swapTrade,
          value: () => tradeFilterStore.displaySwapTrade,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.swapTrade)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.swapsXyz,
          value: () => tradeFilterStore.displaySwapXyz,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.swapsXyz)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.nearIntents,
          value: () => tradeFilterStore.displayNearIntents,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.nearIntents)),
    ];
  }

  @computed
  bool get isMigratingToIronwood =>
      wallet.type == WalletType.zcash && (zcash?.hasOrchardMigratableBalance(wallet) ?? false);

  @computed
  bool get isSyncHeavy {
    if ([
      WalletType.monero,
      WalletType.wownero,
      WalletType.decred,
      WalletType.zcash,
      WalletType.zano
    ].contains(wallet.type)) {
      return true;
    }

    if (wallet.type == WalletType.bitcoin && silentPaymentsScanningActive && hasSilentPayments) {
      return true;
    }

    if (wallet.type == WalletType.litecoin && mwebEnabled && hasMweb) {
      return true;
    }

    return false;
  }

  bool showBridge(CryptoCurrency currency) {
    if (!isEVMCompatibleChain(wallet.type)) return false;

    if (evm!.isUSDT0Token(wallet, currency)) return true;

    return false;
  }

  @action
  void changeAllFilterItems(bool value) {
    for (final item in filterItems) {
      if (item.value() != value) {
        item.onChanged();
      }
    }
    for (final item in exchangeFilterItems) {
      if (item.value() != value) {
        item.onChanged();
      }
    }
  }

  @action
  Future<void> loadCardDesigns() async {
    final accountStyleSettings =
        await BalanceCardStyleSettings.getAll(wallet.walletInfo.internalId);

    late final int numAccounts;
    if (wallet.type == WalletType.monero) {
      numAccounts = monero!.getAccountList(wallet).accounts.length;
    } else if (wallet.type == WalletType.wownero) {
      numAccounts = wow.wownero!.getAccountList(wallet).accounts.length;
    } else if (wallet.type == WalletType.bitcoin) {
      // bitcoin and lightning
      numAccounts = 2;
    } else {
      numAccounts = 1;
    }
    cardDesigns.clear();
    Map<int, int> newOrder = {};

    for (int i = 0; i < numAccounts; i++) {
      late final int index;
      if (balanceViewModel.hasAccounts) {
        index = i;
      } else if (wallet.type == WalletType.bitcoin && i == 1) {
        index = 0;
      } else {
        index = -1;
      }

      final setting = accountStyleSettings.where((e) => e.accountIndex == index).firstOrNull;

      late final CryptoCurrency curr;
      if (wallet.type == WalletType.bitcoin && i == 1) {
        curr = CryptoCurrency.btcln;
      } else {
        curr = wallet.currency;
      }

      cardDesigns.add(CardDesign.fromStyleSettings(setting, curr));
      if (setting?.cardOrder != null) {
        newOrder[setting!.cardOrder] = i;
      }
    }

    // making sure ALL accounts have numbers, even the ones that existed before this feature was a thing
    for (int i = 0; i < numAccounts; i++) {
      if (!newOrder.containsKey(i) && !(wallet.type != WalletType.bitcoin && i == 1)) {
        int free = 0;
        while (newOrder.containsValue(free)) {
          free++;
        }
        if (wallet.type == WalletType.bitcoin) {
          newOrder[free] = 0;
        } else {
          newOrder[free] = i;
        }
      }
    }
    cardOrder = newOrder.asObservable();
  }

  void _checkMweb() {
    if (hasMweb) {
      mwebEnabled = bitcoin!.getMwebEnabled(wallet);
      balanceViewModel.mwebEnabled = mwebEnabled;
    }
  }

  @observable
  WalletType type;

  @observable
  String name;

  @observable
  bool isShowFirstYatIntroduction;

  @observable
  bool isShowSecondYatIntroduction;

  @observable
  bool isShowThirdYatIntroduction;

  @observable
  ObservableList<CardDesign> cardDesigns;

  @observable
  ObservableMap<int, int> cardOrder;

  @computed
  bool get isDarkTheme => appStore.themeStore.currentTheme.isDark;

  @computed
  String get address => wallet.walletAddresses.address;

  @computed
  bool get isTorEnabled => settingsStore.currentBuiltinTor;

  @computed
  SyncStatus get status => wallet.syncStatus;

  @computed
  bool get shouldShowMwebAd {
    if (wallet.type != WalletType.litecoin) return false;

    if (mwebEnabled) return false;

    if (settingsStore.mwebAdDismissed) return false;

    return (Platform.isAndroid || Platform.isIOS) && !wallet.isHardwareWallet;
  }

  @action
  void dismissMwebAd(bool enableMweb) {
    if (enableMweb) setMwebEnabled();

    settingsStore.mwebAdDismissed = true;
  }

  @computed
  BalanceDisplayMode get balanceDisplayMode => appStore.settingsStore.balanceDisplayMode;

  @computed
  @Deprecated("Replaced by showApps")
  bool get shouldShowMarketPlaceInDashboard =>
      appStore.settingsStore.shouldShowMarketPlaceInDashboard;

  @computed
  bool get showApps => appStore.settingsStore.shouldShowMarketPlaceInDashboard;

  @computed
  bool get shouldShowBalanceHiddenMessage =>
      balanceDisplayMode == BalanceDisplayMode.hiddenBalance &&
      appStore.settingsStore.balanceHideCounter < 10;

  @computed
  bool get isAutoGenerateSubaddressesEnabled =>
      settingsStore.autoGenerateSubaddressStatus != AutoGenerateSubaddressStatus.disabled;

  @observable
  WalletBase<Balance, TransactionHistory<TransactionInfo>, TransactionInfo> wallet;

  @computed
  bool get hasLightning =>
      wallet.type == WalletType.bitcoin && wallet.isSoftwareWallet && bitcoin!.useLightning(wallet);

  @computed
  bool get hasWalletConnect =>
      isWalletConnectCompatibleChain(wallet.type) && !wallet.isHardwareWallet;

  @computed
  bool get isTestnet => wallet.type == WalletType.bitcoin && bitcoin!.isTestnet(wallet);

  @computed
  bool get hasRescan => wallet.hasRescan;


  @computed
  bool get hasSilentPayments =>
      wallet.type == WalletType.bitcoin &&
      (bitcoin!.getWalletKeys(wallet)["privateKey"] ?? "").isNotEmpty &&
      !wallet.isHardwareWallet;

  @computed
  bool get isEVMWallet => isEVMCompatibleChain(wallet.type);

  @computed
  List<ChainInfo> get availableChains {
    if (!isEVMWallet) return [];
    return evm!.getAllChains();
  }

  @computed
  ChainInfo? get currentChain {
    if (!isEVMWallet) return null;
    return evm!.getCurrentChain(wallet);
  }

  @action
  Future<void> selectChain(int chainId) async {
    if (!isEVMWallet) return;

    final node = appStore.settingsStore.getCurrentNode(wallet.type, chainId: chainId);

    await evm!.selectChain(wallet, chainId, node: node);
  }

  final KeyService keyService;
  final SharedPreferences sharedPreferences;

  @observable
  bool silentPaymentsScanningActive = false;

  @action
  void setSilentPaymentsScanning(bool active) {
    silentPaymentsScanningActive = active;

    if (hasSilentPayments) {
      bitcoin!.setScanningActive(wallet, active);
    }
  }

  @computed
  bool get hasMweb =>
      wallet.type == WalletType.litecoin &&
      (Platform.isIOS || Platform.isAndroid) &&
      !wallet.isHardwareWallet;

  @observable
  bool mwebEnabled = false;


  @observable
  bool backgroundSyncEnabled = false;

  @action
  Future<bool> isBackgroundSyncEnabled() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final resp = await FlutterDaemon().getBackgroundSyncStatus();
    backgroundSyncEnabled = resp;
    return resp;
  }

  @action
  void toggleSwitchStatusDisplayMode() {
    if (status is SyncingSyncStatus &&
        !((status as SyncingSyncStatus).shouldShowBlocksRemaining())) {
      if (settingsStore.syncStatusDisplayMode == SyncStatusDisplayMode.eta) {
        settingsStore.syncStatusDisplayMode = SyncStatusDisplayMode.blocksRemaining;
      } else {
        settingsStore.syncStatusDisplayMode = SyncStatusDisplayMode.eta;
      }
    }
  }

  @observable
  late bool backgroundSyncNotificationsEnabled =
      sharedPreferences.getBool(PreferencesKey.backgroundSyncNotificationsEnabled) ?? false;

  @action
  Future<void> setBackgroundSyncNotificationsEnabled(bool value) async {
    if (!value) {
      backgroundSyncNotificationsEnabled = false;
      sharedPreferences.setBool(PreferencesKey.backgroundSyncNotificationsEnabled, false);
      return;
    }
    PermissionStatus permissionStatus = await Permission.notification.status;
    if (permissionStatus != PermissionStatus.granted) {
      final resp = await Permission.notification.request();
      if (resp == PermissionStatus.denied) {
        throw Exception("Notification permission denied");
      }
    }
    backgroundSyncNotificationsEnabled = value;
    await sharedPreferences.setBool(PreferencesKey.backgroundSyncNotificationsEnabled, value);
  }

  bool get hasBgsyncNetworkConstraints => Platform.isAndroid;

  bool get hasBgsyncBatteryNotLowConstraints => Platform.isAndroid;

  bool get hasBgsyncChargingConstraints => Platform.isAndroid;

  bool get hasBgsyncDeviceIdleConstraints => Platform.isAndroid;

  @observable
  bool backgroundSyncNetworkUnmetered = false;

  @observable
  bool backgroundSyncBatteryNotLow = false;

  @observable
  bool backgroundSyncCharging = false;

  @observable
  bool backgroundSyncDeviceIdle = false;

  Future<void> _loadConstraints() async {
    if (Platform.isAndroid) {
      backgroundSyncNetworkUnmetered = await FlutterDaemon().getNetworkType();
      backgroundSyncBatteryNotLow = await FlutterDaemon().getBatteryNotLow();
      backgroundSyncCharging = await FlutterDaemon().getRequiresCharging();
      backgroundSyncDeviceIdle = await FlutterDaemon().getDeviceIdle();
    }
  }

  @action
  Future<void> setBackgroundSyncNetworkUnmetered(bool value) async {
    backgroundSyncNetworkUnmetered = value;
    await FlutterDaemon().setNetworkType(value);
    if (await isBackgroundSyncEnabled()) {
      await enableBackgroundSync();
    }
  }

  @action
  Future<void> setBackgroundSyncBatteryNotLow(bool value) async {
    backgroundSyncBatteryNotLow = value;
    await FlutterDaemon().setBatteryNotLow(value);
    if (await isBackgroundSyncEnabled()) {
      await enableBackgroundSync();
    }
  }

  @action
  Future<void> setBackgroundSyncCharging(bool value) async {
    backgroundSyncCharging = value;
    await FlutterDaemon().setRequiresCharging(value);
    if (await isBackgroundSyncEnabled()) {
      await enableBackgroundSync();
    }
  }

  @action
  Future<void> setBackgroundSyncDeviceIdle(bool value) async {
    backgroundSyncDeviceIdle = value;
    await FlutterDaemon().setDeviceIdle(value);
    if (await isBackgroundSyncEnabled()) {
      await enableBackgroundSync();
    }
  }

  bool get hasBatteryOptimization => Platform.isAndroid;

  @observable
  bool batteryOptimizationEnabled = false;

  @action
  Future<bool> isBatteryOptimizationEnabled() async {
    if (!hasBatteryOptimization) {
      return false;
    }
    final resp = await FlutterDaemon().isBatteryOptimizationDisabled();
    batteryOptimizationEnabled = !resp;
    if (batteryOptimizationEnabled && await isBackgroundSyncEnabled()) {
      // If the battery optimization is enabled, we need to disable the background sync
      await disableBackgroundSync();
    }
    return resp;
  }

  @action
  Future<void> disableBatteryOptimization() async {
    final resp = await FlutterDaemon().requestDisableBatteryOptimization();
    unawaited((() async {
      // android doesn't return if the permission was granted, so we need to poll it,
      // minute should be enough for the fallback method (opening settings and changing the permission)
      for (var i = 0; i < 4 * 60; i++) {
        await Future.delayed(Duration(milliseconds: 250));
        await isBatteryOptimizationEnabled();
      }
    })());
  }

  @action
  Future<void> enableBackgroundSync() async {
    if (hasBatteryOptimization && batteryOptimizationEnabled) {
      disableBackgroundSync();
      return;
    }
    final resp = await FlutterDaemon()
        .startBackgroundSync(settingsStore.currentSyncMode.frequency.inMinutes);
    printV("Background sync enabled: $resp");
    backgroundSyncEnabled = true;
  }

  @action
  Future<void> disableBackgroundSync() async {
    final resp = await FlutterDaemon().stopBackgroundSync();
    printV("Background sync disabled: $resp");
    backgroundSyncEnabled = false;
  }


  @action
  double getShadowSpread() {
    double spread = 0;
    if (!appStore.themeStore.currentTheme.isDark)
      spread = 0;
    else if (appStore.themeStore.currentTheme.isDark) spread = 0;
    return spread;
  }

  @action
  double getShadowBlur() {
    double blur = 0;
    if (!appStore.themeStore.currentTheme.isDark)
      blur = 0;
    else if (appStore.themeStore.currentTheme.isDark) blur = 0;
    return blur;
  }

  @action
  void setMwebEnabled() {
    if (!hasMweb) {
      return;
    }

    settingsStore.hasEnabledMwebBefore = true;
    mwebEnabled = true;
    bitcoin!.setMwebEnabled(wallet, true);
    balanceViewModel.mwebEnabled = true;
    settingsStore.mwebAlwaysScan = true;
  }

  @action
  void enablePayjoin() {
    settingsStore.usePayjoin = true;
    settingsStore.showPayjoinCard = false;
    bitcoin!.updatePayjoinState(wallet, true);
  }

  BalanceViewModel balanceViewModel;

  TradeMonitor tradeMonitor;

  AppStore appStore;

  SettingsStore settingsStore;

  YatStore yatStore;

  TradeFilterStore tradeFilterStore;

  OrderFilterStore orderFilterStore;

  TransactionFilterStore transactionFilterStore;

  List<FilterItem> filterItems;

  List<FilterItem> exchangeFilterItems;


  @computed
  bool get isEnabledSwapAction => settingsStore.exchangeStatus != ExchangeApiMode.disabled;


  @observable
  bool hasSwapAction;

  @computed
  bool get isEnabledTradeAction => !settingsStore.disableTradeOption;

  @observable
  bool hasTradeAction;

  @computed
  bool get isEnabledBulletinAction => !settingsStore.disableBulletin;


  ReactionDisposer? _walletChangeDisposer;

  @computed
  bool get hasPowNodes => [WalletType.nano, WalletType.banano].contains(wallet.type);

  Future<void> reconnect() async {
    int? chainId;
    if (isEVMWallet) {
      chainId = evm!.getSelectedChainId(wallet);
    }

    final node = appStore.settingsStore.getCurrentNode(wallet.type, chainId: chainId);
    await wallet.connectToNode(node: node);
    if (hasPowNodes) {
      final powNode = settingsStore.getCurrentPowNode(wallet.type);
      await wallet.connectToPowNode(node: powNode);
    }

    if (hasSilentPayments) {
      bitcoin!.setScanningActive(wallet, silentPaymentsScanningActive);
    }
  }

  @action
  void _onWalletChange(
      WalletBase<Balance, TransactionHistory<TransactionInfo>, TransactionInfo>? wallet) {
    if (wallet == null) {
      return;
    }

    this.wallet = wallet;
    type = wallet.type;
    name = wallet.name;
    loadFilterItems();
  }



  @action
  Future<void> setSyncMode(SyncMode syncMode) async {
    settingsStore.currentSyncMode = syncMode;
    await enableBackgroundSync();
  }

  @computed
  bool get syncAll => settingsStore.currentSyncAll;

  @computed
  bool get builtinTor => settingsStore.currentBuiltinTor;

  @action
  void setBuiltinTor(bool value, BuildContext context) {
    if (value) {
      unawaited(
        showPopUp<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
              alertTitle: S.of(context).tor_connection,
              alertContent: S.of(context).tor_experimental,
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop(true),
            );
          },
        ),
      );
    }
    settingsStore.currentBuiltinTor = value;
    if (value) {
      unawaited(ensureTorStarted(context: context).then((_) async {
        if (settingsStore.currentBuiltinTor == false)
          return; // return when tor got disabled in the meantime;
        int? chainId;
        if (isEVMWallet) {
          chainId = evm!.getSelectedChainId(wallet);
        }
        await wallet.connectToNode(
            node: appStore.settingsStore.getCurrentNode(wallet.type, chainId: chainId));
      }));
    } else {
      unawaited(ensureTorStopped(context: context).then((_) async {
        if (settingsStore.currentBuiltinTor == true)
          return; // return when tor got enabled in the meantime;
        int? chainId;
        if (isEVMWallet) {
          chainId = evm!.getSelectedChainId(wallet);
        }
        await wallet.connectToNode(
            node: appStore.settingsStore.getCurrentNode(wallet.type, chainId: chainId));
      }));
    }
  }


  Future<List<String>> checkForHavenWallets() async {
    final walletInfos = await WalletInfo.getAll();
    return walletInfos
        .where((element) => element.type == WalletType.haven)
        .map((e) => e.name)
        .toList();
  }

  Future<List<String>> checkAffectedWallets() async {
    try {
      // await load file
      final vulnerableSeedsString = await rootBundle
          .loadString('assets/text/cakewallet_weak_bitcoin_seeds_hashed_sorted_version1.txt');
      final vulnerableSeeds = vulnerableSeedsString.split("\n");

      List<String> affectedWallets = [];
      final walletInfos = await WalletInfo.getAll();
      for (var walletInfo in walletInfos) {
        if (walletInfo.type == WalletType.bitcoin) {
          final password = await keyService.getWalletPassword(walletName: walletInfo.name);
          final path = await pathForWallet(name: walletInfo.name, type: walletInfo.type);
          final jsonSource = await read(path: path, password: password);
          final data = json.decode(jsonSource) as Map;
          final mnemonic = data['mnemonic'] as String?;

          if (mnemonic == null) continue;

          final hash = await Cryptography.instance.sha256().hash(utf8.encode(mnemonic));
          final seedSha = bytesToHex(hash.bytes);

          if (vulnerableSeeds.contains(seedSha)) {
            affectedWallets.add(walletInfo.name);
          }
        }
      }

      return affectedWallets;
    } catch (_) {
      return [];
    }
  }


  String getTransactionType(TransactionInfo tx) {
    if (wallet.type == WalletType.bitcoin) {
      if (tx.isReplaced == true) return ' (replaced)';
    }

    if (wallet.chainId == 1 && tx.evmSignatureName == 'approval')
      return ' (${tx.evmSignatureName})';

    return '';
  }

  Future<void> refreshDashboard() async {
    reconnect();
  }
}
