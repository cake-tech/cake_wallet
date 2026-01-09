import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/key_service.dart';
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
import 'package:cake_wallet/store/anonpay/anonpay_transactions_store.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/order_filter_store.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/store/dashboard/payjoin_transactions_store.dart';
import 'package:cake_wallet/store/dashboard/trade_filter_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/dashboard/transaction_filter_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/yat/yat_store.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/utils/tor.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/anonpay_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import 'package:cake_wallet/view_model/dashboard/formatted_item_list.dart';
import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cake_wallet/view_model/settings/sync_mode.dart';
import 'package:cake_wallet/wownero/wownero.dart' as wow;
import 'package:cryptography/cryptography.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/card_design.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/utils/file.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
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

part 'dashboard_view_model.g.dart';

class DashboardViewModel = DashboardViewModelBase with _$DashboardViewModel;

abstract class DashboardViewModelBase with Store {
  DashboardViewModelBase(
      {required this.balanceViewModel,
      required this.tradeMonitor,
      required this.appStore,
      required this.tradesStore,
      required this.tradeFilterStore,
      required this.orderFilterStore,
      required this.transactionFilterStore,
      required this.settingsStore,
      required this.yatStore,
      required this.ordersStore,
      required this.anonpayTransactionsStore,
      required this.payjoinTransactionsStore,
      required this.sharedPreferences,
      required this.keyService})
      : hasTradeAction = true,
        hasSwapAction = true,
        isShowFirstYatIntroduction = false,
        isShowSecondYatIntroduction = false,
        isShowThirdYatIntroduction = false,
        filterItems = {
          S.current.transactions: [
            FilterItem(
                value: () => transactionFilterStore.displayAll,
                caption: S.current.all_transactions,
                onChanged: transactionFilterStore.toggleAll),
            FilterItem(
                value: () => transactionFilterStore.displayIncoming,
                caption: S.current.incoming,
                onChanged: transactionFilterStore.toggleIncoming),
            FilterItem(
                value: () => transactionFilterStore.displayOutgoing,
                caption: S.current.outgoing,
                onChanged: transactionFilterStore.toggleOutgoing),
            if (appStore.wallet!.type == WalletType.bitcoin)
              FilterItem(
                value: () => transactionFilterStore.displaySilentPayments,
                caption: S.current.silent_payments,
                onChanged: transactionFilterStore.toggleSilentPayments,
              ),
            // FilterItem(
            //     value: () => false,
            //     caption: S.current.transactions_by_date,
            //     onChanged: null),
          ],
          'Orders': [
            FilterItem(
                value: () => orderFilterStore.displayCakePay,
                caption: 'Cake Pay',
                onChanged: () =>
                    orderFilterStore.toggleDisplayOrder(OrderProviderDescription.cakePay)),
          ],
          S.current.trades: [
            FilterItem(
                value: () => tradeFilterStore.displayAllTrades,
                caption: S.current.all_trades,
                onChanged: () =>
                    tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.all)),
            FilterItem(
                value: () => tradeFilterStore.displayChangeNow,
                caption: ExchangeProviderDescription.changeNow.title,
                onChanged: () =>
                    tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.changeNow)),
            FilterItem(
                value: () => tradeFilterStore.displaySideShift,
                caption: ExchangeProviderDescription.sideShift.title,
                onChanged: () =>
                    tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.sideShift)),
            FilterItem(
                value: () => tradeFilterStore.displaySimpleSwap,
                caption: ExchangeProviderDescription.simpleSwap.title,
                onChanged: () =>
                    tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.simpleSwap)),
            FilterItem(
                value: () => tradeFilterStore.displayTrocador,
                caption: ExchangeProviderDescription.trocador.title,
                onChanged: () =>
                    tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.trocador)),
            FilterItem(
                value: () => tradeFilterStore.displayExolix,
                caption: ExchangeProviderDescription.exolix.title,
                onChanged: () =>
                    tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.exolix)),
            FilterItem(
                value: () => tradeFilterStore.displayChainflip,
                caption: ExchangeProviderDescription.chainflip.title,
                onChanged: () =>
                    tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.chainflip)),
            FilterItem(
                value: () => tradeFilterStore.displayThorChain,
                caption: ExchangeProviderDescription.thorChain.title,
                onChanged: () =>
                    tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.thorChain)),
            FilterItem(
                value: () => tradeFilterStore.displayLetsExchange,
                caption: ExchangeProviderDescription.letsExchange.title,
                onChanged: () => tradeFilterStore
                    .toggleDisplayExchange(ExchangeProviderDescription.letsExchange)),
            FilterItem(
                value: () => tradeFilterStore.displayStealthEx,
                caption: ExchangeProviderDescription.stealthEx.title,
                onChanged: () =>
                    tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.stealthEx)),
            FilterItem(
                value: () => tradeFilterStore.displayXOSwap,
                caption: ExchangeProviderDescription.xoSwap.title,
                onChanged: () =>
                    tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.xoSwap)),
            FilterItem(
                value: () => tradeFilterStore.displaySwapTrade,
                caption: ExchangeProviderDescription.swapTrade.title,
                onChanged: () =>
                    tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.swapTrade)),
            FilterItem(
                value: () => tradeFilterStore.displaySwapXyz,
                caption: ExchangeProviderDescription.swapsXyz.title,
                onChanged: () =>
                    tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.swapsXyz)),
          ]
        },
        subname = '',
        name = appStore.wallet!.name,
        type = appStore.wallet!.type,
        transactions = ObservableList<TransactionListItem>(),
        cardDesigns = ObservableList<CardDesign>(),
        wallet = appStore.wallet! {
    showDecredInfoCard = wallet.type == WalletType.decred &&
        (sharedPreferences.getBool(PreferencesKey.showDecredInfoCard) ?? true);

    name = wallet.name;
    type = wallet.type;
    isShowFirstYatIntroduction = false;
    isShowSecondYatIntroduction = false;
    isShowThirdYatIntroduction = false;
    unawaited(isBackgroundSyncEnabled());
    unawaited(isBatteryOptimizationEnabled());
    unawaited(_loadConstraints());
    final _wallet = wallet;

    if (_wallet.type == WalletType.monero) {
      subname = monero!.getCurrentAccount(_wallet).label;

      _onMoneroAccountChangeReaction = reaction(
          (_) => monero!.getMoneroWalletDetails(wallet).account,
          (Account account) => _onMoneroAccountChange(_wallet));

      _onMoneroBalanceChangeReaction = reaction(
          (_) => monero!.getMoneroWalletDetails(wallet).balance,
          (MoneroBalance balance) => _onMoneroTransactionsUpdate(_wallet));

      final _accountTransactions = _wallet.transactionHistory.transactions.values
          .where((tx) =>
              monero!.getTransactionInfoAccountId(tx) == monero!.getCurrentAccount(wallet).id)
          .toList();

      final sortedTransactions = [..._accountTransactions];
      sortedTransactions.sort((a, b) => a.date.compareTo(b.date));

      transactions = ObservableList.of(
        sortedTransactions.map(
          (transaction) => TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore,
            key: ValueKey('monero_transaction_history_item_${transaction.id}_key'),
          ),
        ),
      );
    } else if (_wallet.type == WalletType.wownero) {
      subname = wow.wownero!.getCurrentAccount(_wallet).label;

      _onMoneroAccountChangeReaction = reaction(
          (_) => wow.wownero!.getWowneroWalletDetails(wallet).account,
          (wow.Account account) => _onMoneroAccountChange(_wallet));

      _onMoneroBalanceChangeReaction = reaction(
          (_) => wow.wownero!.getWowneroWalletDetails(wallet).balance,
          (wow.WowneroBalance balance) => _onMoneroTransactionsUpdate(_wallet));

      final _accountTransactions = _wallet.transactionHistory.transactions.values
          .where((tx) =>
              wow.wownero!.getTransactionInfoAccountId(tx) ==
              wow.wownero!.getCurrentAccount(wallet).id)
          .toList();

      final sortedTransactions = [..._accountTransactions];
      sortedTransactions.sort((a, b) => a.date.compareTo(b.date));

      transactions = ObservableList.of(
        sortedTransactions.map(
          (transaction) => TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore,
            key: ValueKey('wownero_transaction_history_item_${transaction.id}_key'),
          ),
        ),
      );
    } else {
      final sortedTransactions = [...wallet.transactionHistory.transactions.values];
      sortedTransactions.sort((a, b) => a.date.compareTo(b.date));

      transactions = ObservableList.of(
        sortedTransactions.map(
          (transaction) => TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore,
            key: ValueKey('${_wallet.type.name}_transaction_history_item_${transaction.id}_key'),
          ),
        ),
      );
    }

    // TODO: nano sub-account generation is disabled:
    // if (_wallet.type == WalletType.nano || _wallet.type == WalletType.banano) {
    //   subname = nano!.getCurrentAccount(_wallet).label;
    // }

    _walletChangeDisposer?.reaction.dispose();
    _walletChangeDisposer = reaction((_) => appStore.wallet, (wallet) {
      _onWalletChange(wallet);
      _checkMweb();
      loadCardDesigns();
      showDecredInfoCard = wallet?.type == WalletType.decred &&
          sharedPreferences.getBool(PreferencesKey.showDecredInfoCard) != false;

      tradeMonitor.stopTradeMonitoring();
      tradeMonitor.monitorActiveTrades(wallet!.id);
    });

    _transactionDisposer?.reaction.dispose();
    _transactionDisposer = reaction((_) {
      final length = appStore.wallet!.transactionHistory.transactions.length;
      if (length == 0) {
        return 0;
      }
      int confirmations = 1;
      if (![WalletType.solana, WalletType.tron].contains(wallet.type)) {
        try {
          confirmations =
              appStore.wallet!.transactionHistory.transactions.values.first.confirmations +
                  appStore.wallet!.transactionHistory.transactions.values.last.confirmations +
                  1;
        } catch (_) {}
      }
      return length * confirmations;
    }, _transactionDisposerCallback);

    if (hasSilentPayments) {
      silentPaymentsScanningActive = bitcoin!.getScanningActive(wallet);

      reaction((_) => wallet.syncStatus, (SyncStatus syncStatus) {
        silentPaymentsScanningActive = bitcoin!.getScanningActive(wallet);
      });
    }

    loadCardDesigns();

    _checkMweb();
    reaction((_) => settingsStore.mwebAlwaysScan, (bool value) => _checkMweb());

    reaction((_) => tradesStore.trades, (_) => tradeMonitor.monitorActiveTrades(wallet.id));

    tradeMonitor.monitorActiveTrades(wallet.id);
  }

  bool _isTransactionDisposerCallbackRunning = false;


  Future<void> loadCardDesigns() async {
    if (cardDesigns.isNotEmpty) {
      cardDesigns.clear();
    }

    final accountStyleSettings =
          await BalanceCardStyleSettings.getAll(wallet.walletInfo.internalId);

      late final int numAccounts;
      if (wallet.type == WalletType.monero) {
        numAccounts = monero!.getAccountList(wallet).accounts.length;
      } else if (wallet.type == WalletType.wownero) {
        numAccounts = wow.wownero!.getAccountList(wallet).accounts.length;
      } else {
        numAccounts = 1;
      }

      for (int i = 0; i < numAccounts; i++) {
        final setting = accountStyleSettings
            .where((e) => e.accountIndex == (balanceViewModel.hasAccounts ? i : -1))
            .firstOrNull;

        cardDesigns.add(CardDesign.fromStyleSettings(setting, wallet.currency));
      }
  }


  void _transactionDisposerCallback(int _) async {
    // Simple check to prevent the callback from being called multiple times in the same frame
    if (_isTransactionDisposerCallbackRunning) return;
    _isTransactionDisposerCallbackRunning = true;
    await Future.delayed(Duration.zero);

    try {
      final currentAccountId = wallet.type == WalletType.monero
          ? monero!.getCurrentAccount(wallet).id
          : wallet.type == WalletType.wownero
              ? wow.wownero!.getCurrentAccount(wallet).id
              : null;
      final List<TransactionInfo> relevantTxs = [];

      for (final tx in appStore.wallet!.transactionHistory.transactions.values) {
        bool isRelevant = true;
        if (wallet.type == WalletType.monero) {
          isRelevant = monero!.getTransactionInfoAccountId(tx) == currentAccountId;
        } else if (wallet.type == WalletType.wownero) {
          isRelevant = wow.wownero!.getTransactionInfoAccountId(tx) == currentAccountId;
        }

        if (isRelevant) {
          relevantTxs.add(tx);
        }
      }
      // printV("Transaction disposer callback (relevantTxs: ${relevantTxs.length} current: ${transactions.length})");

      transactions.clear();
      transactions.addAll(relevantTxs.map((tx) => TransactionListItem(
            transaction: tx,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore,
            key: ValueKey('${wallet.type.name}_transaction_history_item_${tx.id}_key'),
          )));
    } finally {
      _isTransactionDisposerCallbackRunning = false;
    }
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
  ObservableList<TransactionListItem> transactions;

  @observable
  String subname;

  @observable
  bool isShowFirstYatIntroduction;

  @observable
  bool isShowSecondYatIntroduction;

  @observable
  bool isShowThirdYatIntroduction;

  @observable
  ObservableList<CardDesign> cardDesigns;

  @computed
  bool get isDarkTheme => appStore.themeStore.currentTheme.isDark;

  @computed
  String get address => wallet.walletAddresses.address;

  @computed
  bool get isTorEnabled => CakeTor.instance!.enabled;

  @computed
  SyncStatus get status => wallet.syncStatus;

  @computed
  String get syncStatusText {
    var statusText = '';

    if (status is SyncingSyncStatus) {
      statusText = S.current.Blocks_remaining(status.toString());
    }

    if (status is FailedSyncStatus || status is LostConnectionSyncStatus) {
      statusText = S.current.please_try_to_connect_to_another_node;
    }

    if (status is ProcessingSyncStatus) {
      statusText = (status as ProcessingSyncStatus).message ?? S.current.processing;
    }

    return statusText;
  }

  @computed
  BalanceDisplayMode get balanceDisplayMode => appStore.settingsStore.balanceDisplayMode;

  @computed
  bool get shouldShowMarketPlaceInDashboard =>
      appStore.settingsStore.shouldShowMarketPlaceInDashboard;

  @computed
  List<TradeListItem> get trades =>
      tradesStore.trades.where((trade) => trade.trade.walletId == wallet.id).toList();

  @computed
  List<OrderListItem> get orders =>
      ordersStore.orders.where((item) => item.order.walletId == wallet.id).toList();

  @computed
  List<AnonpayTransactionListItem> get anonpayTransactions => anonpayTransactionsStore.transactions
      .where((item) => item.transaction.walletId == wallet.id)
      .toList();

  @computed
  List<PayjoinTransactionListItem> get payjoinTransactions => payjoinTransactionsStore.transactions
      .where((item) => item.session.walletId == wallet.id)
      .toList();

  @computed
  double get price => balanceViewModel.price;

  @computed
  bool get isAutoGenerateSubaddressesEnabled =>
      settingsStore.autoGenerateSubaddressStatus != AutoGenerateSubaddressStatus.disabled;

  @computed
  List<ActionListItem> get items {
    final _items = <ActionListItem>[];

    _items.addAll(
        transactionFilterStore.filtered(transactions: [...transactions, ...anonpayTransactions]));
    _items.addAll(tradeFilterStore.filtered(trades: trades, wallet: wallet));
    _items.addAll(orderFilterStore.filtered(orders: orders, wallet: wallet));

    if (payjoinTransactions.isNotEmpty) {
      final _payjoinTransactions = payjoinTransactions;
      _items.forEach((e) {
        if (e is TransactionListItem &&
            _payjoinTransactions.any((t) => t.session.txId == e.transaction.id)) {
          _payjoinTransactions.firstWhere((t) => t.session.txId == e.transaction.id).transaction =
              e.transaction;
        }
      });
      _items.addAll(_payjoinTransactions);
      _items.removeWhere((e) => (e is TransactionListItem &&
          _payjoinTransactions.any((t) => t.session.txId == e.transaction.id)));
    }

    return formattedItemsList(_items);
  }

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> wallet;

  @computed
  bool get isTestnet => wallet.type == WalletType.bitcoin && bitcoin!.isTestnet(wallet);

  @computed
  bool get hasRescan => wallet.hasRescan;

  @computed
  bool get hasBackgroundSync => [
        WalletType.monero,
      ].contains(wallet.type);

  @computed
  bool get isMoneroViewOnly {
    if (wallet.type != WalletType.monero) return false;
    return monero!.isViewOnly();
  }

  @computed
  String? get getMoneroError {
    if (wallet.type != WalletType.monero) return null;
    try {
      monero!.monerocCheck();
    } catch (e) {
      return e.toString();
    }
    return null;
  }

  @computed
  String? get getWowneroError {
    if (wallet.type != WalletType.wownero) return null;
    try {
      wow.wownero!.wownerocCheck();
    } catch (e) {
      return e.toString();
    }
    return null;
  }

  List<String> get isMoneroWalletBrokenReasons {
    if (wallet.type != WalletType.monero) return [];
    final keys = monero!.getKeys(wallet);
    List<String> errors = [
      // leaving these commented out for now, I'll be able to fix that properly in the airgap update
      // to not cause work duplication, this will do the job as well, it will be slightly less precise
      // about what happened - but still enough.
      // if (keys['privateSpendKey'] == List.generate(64, (index) => "0").join("")) "Private spend key is 0",
      if (keys['privateViewKey'] == List.generate(64, (index) => "0").join("") &&
          !wallet.isHardwareWallet)
        "private view key is 0",
      // if (keys['publicSpendKey'] == List.generate(64, (index) => "0").join("")) "public spend key is 0",
      if (keys['publicViewKey'] == List.generate(64, (index) => "0").join(""))
        "public view key is 0",
      // if (wallet.seed == null) "wallet seed is null",
      // if (wallet.seed == "") "wallet seed is empty",
      if (monero!.getSubaddressList(wallet).getAll(wallet)[0].address ==
          "41d7FXjswpK1111111111111111111111111111111111111111111111111111111111111111111111111111112KhNi4")
        "primary address is invalid, you won't be able to receive / spend funds",
    ];
    return errors;
  }

  @computed
  bool get hasSilentPayments =>
      wallet.type == WalletType.bitcoin &&
      (bitcoin!.getWalletKeys(wallet)["privateKey"] ?? "").isNotEmpty &&
      !wallet.isHardwareWallet;

  @computed
  bool get showSilentPaymentsCard => hasSilentPayments && settingsStore.silentPaymentsCardDisplay;

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

  @computed
  bool get showMwebCard => hasMweb && settingsStore.mwebCardDisplay && !mwebEnabled;

  @observable
  bool mwebEnabled = false;

  @observable
  late bool showDecredInfoCard;

  @computed
  bool get showPayjoinCard =>
      wallet.type == WalletType.bitcoin &&
      settingsStore.showPayjoinCard &&
      !settingsStore.usePayjoin &&
      DeviceInfo.instance.isMobile;

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
    if (status is SyncingSyncStatus && !((status as SyncingSyncStatus).shouldShowBlocksRemaining())) {
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

  @computed
  bool get hasEnabledMwebBefore => settingsStore.hasEnabledMwebBefore;

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
  void dismissMweb() {
    settingsStore.mwebCardDisplay = false;
    balanceViewModel.mwebEnabled = false;
    settingsStore.mwebAlwaysScan = false;
    mwebEnabled = false;
    bitcoin!.setMwebEnabled(wallet, false);
  }

  @action
  void dismissDecredInfoCard() {
    showDecredInfoCard = false;
    sharedPreferences.setBool(PreferencesKey.showDecredInfoCard, false);
  }

  @action
  void dismissPayjoin() {
    settingsStore.showPayjoinCard = false;
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

  TradesStore tradesStore;

  OrdersStore ordersStore;

  TradeFilterStore tradeFilterStore;

  OrderFilterStore orderFilterStore;

  AnonpayTransactionsStore anonpayTransactionsStore;

  TransactionFilterStore transactionFilterStore;

  PayjoinTransactionsStore payjoinTransactionsStore;

  Map<String, List<FilterItem>> filterItems;

  bool get isBuyEnabled => settingsStore.isBitcoinBuyEnabled;

  bool get shouldShowYatPopup => settingsStore.shouldShowYatPopup;

  @action
  void furtherShowYatPopup(bool shouldShow) => settingsStore.shouldShowYatPopup = shouldShow;

  @computed
  bool get isEnabledSwapAction => settingsStore.exchangeStatus != ExchangeApiMode.disabled;

  @computed
  bool get canSend => wallet.canSend();

  @observable
  bool hasSwapAction;

  @computed
  bool get isEnabledTradeAction => !settingsStore.disableTradeOption;

  @observable
  bool hasTradeAction;

  @computed
  bool get isEnabledBulletinAction => !settingsStore.disableBulletin;

  ReactionDisposer? _onMoneroAccountChangeReaction;

  ReactionDisposer? _onMoneroBalanceChangeReaction;

  ReactionDisposer? _transactionDisposer;

  ReactionDisposer? _walletChangeDisposer;

  @computed
  bool get hasPowNodes => [WalletType.nano, WalletType.banano].contains(wallet.type);

  @computed
  bool get hasSignMessages {
    if (wallet.isHardwareWallet) {
      return false;
    }
    switch (wallet.type) {
      case WalletType.monero:
      case WalletType.litecoin:
      case WalletType.bitcoin:
      case WalletType.bitcoinCash:
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.solana:
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.tron:
      case WalletType.wownero:
      case WalletType.decred:
      case WalletType.dogecoin:
        return true;
      case WalletType.zano:
      case WalletType.haven:
      case WalletType.none:
        return false;
    }
  }

  bool get showRepWarning {
    if (wallet.type != WalletType.nano) {
      return false;
    }

    if (!settingsStore.shouldShowRepWarning) {
      return false;
    }

    return !nano!.isRepOk(wallet);
  }

  Future<void> reconnect() async {
    final node = appStore.settingsStore.getCurrentNode(wallet.type);
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
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>? wallet) {
    if (wallet == null) {
      return;
    }

    this.wallet = wallet;
    type = wallet.type;
    name = wallet.name;

    if (wallet.type == WalletType.monero) {
      subname = monero!.getCurrentAccount(wallet).label;

      _onMoneroAccountChangeReaction?.reaction.dispose();
      _onMoneroBalanceChangeReaction?.reaction.dispose();

      _onMoneroAccountChangeReaction = reaction(
          (_) => monero!.getMoneroWalletDetails(wallet).account,
          (Account account) => _onMoneroAccountChange(wallet));

      _onMoneroBalanceChangeReaction = reaction(
          (_) => monero!.getMoneroWalletDetails(wallet).balance,
          (MoneroBalance balance) => _onMoneroTransactionsUpdate(wallet));

      _onMoneroTransactionsUpdate(wallet);
    } else if (wallet.type == WalletType.wownero) {
      subname = wow.wownero!.getCurrentAccount(wallet).label;

      _onMoneroAccountChangeReaction?.reaction.dispose();
      _onMoneroBalanceChangeReaction?.reaction.dispose();

      _onMoneroAccountChangeReaction = reaction(
          (_) => wow.wownero!.getWowneroWalletDetails(wallet).account,
          (wow.Account account) => _onMoneroAccountChange(wallet));

      _onMoneroBalanceChangeReaction = reaction(
          (_) => wow.wownero!.getWowneroWalletDetails(wallet).balance,
          (wow.WowneroBalance balance) => _onMoneroTransactionsUpdate(wallet));

      _onMoneroTransactionsUpdate(wallet);
    } else {
      // FIX-ME: Check for side effects
      // subname = null;
      subname = '';

      transactions.clear();

      transactions.addAll(
        wallet.transactionHistory.transactions.values.map(
          (transaction) => TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore,
            key: ValueKey('${wallet.type.name}_transaction_history_item_${transaction.id}_key'),
          ),
        ),
      );
    }

    _transactionDisposer?.reaction.dispose();

    _transactionDisposer = reaction((_) {
      final length = appStore.wallet!.transactionHistory.transactions.length;
      if (length == 0) {
        return 0;
      }
      int confirmations = 1;
      if (![WalletType.solana, WalletType.tron].contains(wallet.type)) {
        try {
          confirmations =
              appStore.wallet!.transactionHistory.transactions.values.first.confirmations +
                  appStore.wallet!.transactionHistory.transactions.values.last.confirmations +
                  1;
        } catch (_) {}
      }
      return length * confirmations;
    }, _transactionDisposerCallback);
  }

  @action
  void _onMoneroAccountChange(WalletBase wallet) {
    if (wallet.type == WalletType.monero) {
      subname = monero!.getCurrentAccount(wallet).label;
    } else if (wallet.type == WalletType.wownero) {
      subname = wow.wownero!.getCurrentAccount(wallet).label;
    }
    _onMoneroTransactionsUpdate(wallet);
  }

  @action
  void _onMoneroTransactionsUpdate(WalletBase wallet) {
    transactions.clear();
    if (wallet.type == WalletType.monero) {
      final _accountTransactions = monero!
          .getTransactionHistory(wallet)
          .transactions
          .values
          .where((tx) =>
              monero!.getTransactionInfoAccountId(tx) == monero!.getCurrentAccount(wallet).id)
          .toList();

      transactions.addAll(
        _accountTransactions.map(
          (transaction) => TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore,
            key: ValueKey('monero_transaction_history_item_${transaction.id}_key'),
          ),
        ),
      );
    } else if (wallet.type == WalletType.wownero) {
      final _accountTransactions = wow.wownero!
          .getTransactionHistory(wallet)
          .transactions
          .values
          .where((tx) =>
              wow.wownero!.getTransactionInfoAccountId(tx) ==
              wow.wownero!.getCurrentAccount(wallet).id)
          .toList();

      transactions.addAll(
        _accountTransactions.map(
          (transaction) => TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore,
            key: ValueKey('wownero_transaction_history_item_${transaction.id}_key'),
          ),
        ),
      );
    }
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
        await wallet.connectToNode(node: appStore.settingsStore.getCurrentNode(wallet.type));
      }));
    } else {
      unawaited(ensureTorStopped(context: context).then((_) async {
        if (settingsStore.currentBuiltinTor == true)
          return; // return when tor got enabled in the meantime;
        await wallet.connectToNode(node: appStore.settingsStore.getCurrentNode(wallet.type));
      }));
    }
  }

  @action
  void setSyncAll(bool value) => settingsStore.currentSyncAll = value;

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

  static ServicesResponse? cachedServicesResponse;

  Future<ServicesResponse> getServicesStatus() async {
    if (cachedServicesResponse != null) {
      return cachedServicesResponse!;
    }
    cachedServicesResponse = await _getServicesStatus();
    return cachedServicesResponse!;
  }

  Future<ServicesResponse> _getServicesStatus() async {
    try {
      if (isEnabledBulletinAction) {
        final res = await ProxyWrapper().get(
          clearnetUri: Uri.https(
            "service-api.cakewallet.com",
            "/v1/active-notices",
            {'key': secrets.fiatApiKey},
          ),
          onionUri: Uri.http(
            "jpirgl4lrwzjgdqj2nsv3g7twhp2efzty5d3cnypktyczzqfc5qcwwyd.onion",
            "/v1/active-notices",
            {'key': secrets.fiatApiKey},
          ),
        );
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw res.body;
        }

        final oldSha = sharedPreferences.getString(PreferencesKey.serviceStatusShaKey);

        final hash = await Cryptography.instance.sha256().hash(utf8.encode(res.body));
        final currentSha = bytesToHex(hash.bytes);

        final hasUpdates = oldSha != currentSha;

        return ServicesResponse.fromJson(
          json.decode(res.body) as Map<String, dynamic>,
          hasUpdates,
          currentSha,
        );
      } else {
        return ServicesResponse([], false, '');
      }
    } catch (e) {
      return ServicesResponse([], false, '');
    }
  }

  String getTransactionType(TransactionInfo tx) {
    if (wallet.type == WalletType.bitcoin) {
      if (tx.isReplaced == true) return ' (replaced)';
    }

    if (wallet.type == WalletType.ethereum && tx.evmSignatureName == 'approval')
      return ' (${tx.evmSignatureName})';
    return '';
  }

  Future<void> refreshDashboard() async {
    reconnect();
  }
}
