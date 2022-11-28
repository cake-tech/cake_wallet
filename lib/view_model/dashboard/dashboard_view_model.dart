import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/balance.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/entities/transaction_history.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/store/yat/yat_store.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_display_mode.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/dashboard/trade_filter_store.dart';
import 'package:cake_wallet/store/dashboard/transaction_filter_store.dart';
import 'package:cake_wallet/view_model/dashboard/formatted_item_list.dart';
import 'package:cake_wallet/monero/monero.dart';

part 'dashboard_view_model.g.dart';

class DashboardViewModel = DashboardViewModelBase with _$DashboardViewModel;

abstract class DashboardViewModelBase with Store {
  DashboardViewModelBase(
      {required this.balanceViewModel,
      required this.appStore,
      required this.tradesStore,
      required this.tradeFilterStore,
      required this.transactionFilterStore,
      required this.settingsStore,
      required this.yatStore,
      required this.ordersStore})
  : isOutdatedElectrumWallet = false,
    hasSellAction = false,
    isEnabledSellAction = false,
    hasBuyAction = false,
    isEnabledBuyAction = false,
    hasExchangeAction = false,
    isShowFirstYatIntroduction = false,
    isShowSecondYatIntroduction = false,
    isShowThirdYatIntroduction = false,
    filterItems = {
      S.current.transactions: [
        FilterItem(
            value: transactionFilterStore.displayAll,
            caption: S.current.all_transactions,
            onChanged: () => transactionFilterStore.toggleIAll()),
        FilterItem(
            value: transactionFilterStore.displayIncoming,
            caption: S.current.incoming,
            onChanged: () => transactionFilterStore.toggleIncoming()),
        FilterItem(
            value: transactionFilterStore.displayOutgoing,
            caption: S.current.outgoing,
            onChanged: () => transactionFilterStore.toggleOutgoing()),
        // FilterItem(
        //     value: () => false,
        //     caption: S.current.transactions_by_date,
        //     onChanged: null),
      ],
      S.current.trades: [
        FilterItem(
            value: tradeFilterStore.displayAllTrades,
            caption: S.current.all_trades,
            onChanged: () => tradeFilterStore
                .toggleDisplayExchange(ExchangeProviderDescription.all)),
        FilterItem(
            value: tradeFilterStore.displayChangeNow,
            caption: 'Change.NOW',
            onChanged: () => tradeFilterStore
                .toggleDisplayExchange(ExchangeProviderDescription.changeNow)),
        FilterItem(
            value:  tradeFilterStore.displaySideShift,
            caption: 'SideShift',
            onChanged: () => tradeFilterStore
                .toggleDisplayExchange(ExchangeProviderDescription.sideShift)),
      ]
    },
    subname = '',
    name = appStore.wallet!.name,
    type = appStore.wallet!.type,
    transactions = ObservableList<TransactionListItem>(),
    wallet = appStore.wallet! {
    name = wallet.name;
    type = wallet.type;
    isOutdatedElectrumWallet =
        wallet.type == WalletType.bitcoin && wallet.seed.split(' ').length < 24;
    isShowFirstYatIntroduction = false;
    isShowSecondYatIntroduction = false;
    isShowThirdYatIntroduction = false;
    updateActions();

    final _wallet = wallet;

    if (_wallet.type == WalletType.monero) {
      subname = monero!.getCurrentAccount(_wallet).label;

      _onMoneroAccountChangeReaction = reaction((_) => monero!.getMoneroWalletDetails(wallet)
          .account, (Account account) => _onMoneroAccountChange(_wallet));

      _onMoneroBalanceChangeReaction = reaction((_) => monero!.getMoneroWalletDetails(wallet).balance,
          (MoneroBalance balance) => _onMoneroTransactionsUpdate(_wallet));

      final _accountTransactions = _wallet
          .transactionHistory.transactions.values
          .where((tx) => monero!.getTransactionInfoAccountId(tx) == monero!.getCurrentAccount(wallet).id)
          .toList();

      transactions = ObservableList.of(_accountTransactions.map((transaction) =>
          TransactionListItem(
              transaction: transaction,
              balanceViewModel: balanceViewModel,
              settingsStore: appStore.settingsStore)));
    } else {
      transactions = ObservableList.of(wallet
          .transactionHistory.transactions.values
          .map((transaction) => TransactionListItem(
              transaction: transaction,
              balanceViewModel: balanceViewModel,
              settingsStore: appStore.settingsStore)));
    }

    reaction((_) => appStore.wallet, _onWalletChange);

    connectMapToListWithTransform(
        appStore.wallet!.transactionHistory.transactions,
        transactions,
        (TransactionInfo? transaction) => TransactionListItem(
            transaction: transaction!,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore),
        filter: (TransactionInfo? transaction) {
          if (transaction == null) {
            return false;
          }

          final wallet = _wallet;
          if (wallet.type == WalletType.monero) {
            return monero!.getTransactionInfoAccountId(transaction) == monero!.getCurrentAccount(wallet).id;
          }

          return true;
    });
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

  @computed
  String get address => wallet.walletAddresses.address;

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

    return statusText;
  }

  @computed
  BalanceDisplayMode get balanceDisplayMode =>
      appStore.settingsStore.balanceDisplayMode;

  @computed
  List<TradeListItem> get trades => tradesStore.trades
      .where((trade) => trade.trade.walletId == wallet.id)
      .toList();

  @computed
  List<OrderListItem> get orders => ordersStore.orders
      .where((item) => item.order.walletId == wallet.id)
      .toList();

  @computed
  double get price => balanceViewModel.price;

  @computed
  List<ActionListItem> get items {
    final _items = <ActionListItem>[];

    _items.addAll(transactionFilterStore.filtered(transactions: transactions));
    _items.addAll(tradeFilterStore.filtered(trades: trades, wallet: wallet));
    _items.addAll(orders);

    return formattedItemsList(_items);
  }

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>
      wallet;

  bool get hasRescan => wallet.type == WalletType.monero;

  BalanceViewModel balanceViewModel;

  AppStore appStore;

  SettingsStore settingsStore;

  YatStore yatStore;

  TradesStore tradesStore;

  OrdersStore ordersStore;

  TradeFilterStore tradeFilterStore;

  TransactionFilterStore transactionFilterStore;

  Map<String, List<FilterItem>> filterItems;

  bool get isBuyEnabled => settingsStore.isBitcoinBuyEnabled;

  bool get shouldShowYatPopup => settingsStore.shouldShowYatPopup;

  @action
  void furtherShowYatPopup(bool shouldShow) =>
      settingsStore.shouldShowYatPopup = shouldShow;

  @computed
  bool get isEnabledExchangeAction => !settingsStore.disableExchange;

  @observable
  bool hasExchangeAction;

  @observable
  bool isEnabledBuyAction;

  @observable
  bool hasBuyAction;

  @observable
  bool isEnabledSellAction;

  @observable
  bool hasSellAction;

  ReactionDisposer? _onMoneroAccountChangeReaction;

  ReactionDisposer? _onMoneroBalanceChangeReaction;

  @observable
  bool isOutdatedElectrumWallet;

  Future<void> reconnect() async {
    final node = appStore.settingsStore.getCurrentNode(wallet.type);
    await wallet.connectToNode(node: node);
  }

  @action
  void _onWalletChange(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>?
          wallet) {
    if (wallet == null) {
      return;
    }

    this.wallet = wallet;
    type = wallet.type;
    name = wallet.name;
    isOutdatedElectrumWallet =
        wallet.type == WalletType.bitcoin && wallet.seed.split(' ').length < 24;
    updateActions();

    if (wallet.type == WalletType.monero) {
      subname = monero!.getCurrentAccount(wallet).label;

      _onMoneroAccountChangeReaction?.reaction.dispose();
      _onMoneroBalanceChangeReaction?.reaction.dispose();

      _onMoneroAccountChangeReaction = reaction((_) => monero!.getMoneroWalletDetails(wallet)
          .account, (Account account) => _onMoneroAccountChange(wallet));

      _onMoneroBalanceChangeReaction = reaction((_) => monero!.getMoneroWalletDetails(wallet).balance,
          (MoneroBalance balance) => _onMoneroTransactionsUpdate(wallet));

      _onMoneroTransactionsUpdate(wallet);
    } else {
      // FIX-ME: Check for side effects
      // subname = null;
      subname = '';

      transactions.clear();

      transactions.addAll(wallet.transactionHistory.transactions.values.map(
          (transaction) => TransactionListItem(
              transaction: transaction,
              balanceViewModel: balanceViewModel,
              settingsStore: appStore.settingsStore)));
    }

    connectMapToListWithTransform(
        appStore.wallet!.transactionHistory.transactions,
        transactions,
        (TransactionInfo? transaction)
          => TransactionListItem(
            transaction: transaction!,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore),
        filter: (TransactionInfo? tx) {
          if (tx == null) {
            return false;
          }

          if (wallet.type == WalletType.monero) {
            return monero!.getTransactionInfoAccountId(tx) == monero!.getCurrentAccount(wallet).id;
          }

          return true;
    });
  }

  @action
  void _onMoneroAccountChange(WalletBase wallet) {
    subname = monero!.getCurrentAccount(wallet).label;
    _onMoneroTransactionsUpdate(wallet);
  }

  @action
  void _onMoneroTransactionsUpdate(WalletBase wallet) {
    transactions.clear();

    final _accountTransactions = monero!.getTransactionHistory(wallet).transactions.values
        .where((tx) => monero!.getTransactionInfoAccountId(tx) == monero!.getCurrentAccount(wallet).id)
        .toList();

    transactions.addAll(_accountTransactions.map((transaction) =>
        TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore)));
  }

  void updateActions() {
    hasExchangeAction = !isHaven;
    isEnabledBuyAction = wallet.type != WalletType.haven
      && wallet.type != WalletType.monero;
    hasBuyAction = !isMoneroOnly && !isHaven;
    isEnabledSellAction = wallet.type != WalletType.haven
      && wallet.type != WalletType.monero
      && wallet.type != WalletType.litecoin;
    hasSellAction = !isMoneroOnly && !isHaven;
  }
}
