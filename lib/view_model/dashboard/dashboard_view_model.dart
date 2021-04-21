import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/entities/balance.dart';
import 'package:cake_wallet/entities/order.dart';
import 'package:cake_wallet/entities/transaction_history.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/monero/account.dart';
import 'package:cake_wallet/monero/monero_balance.dart';
import 'package:cake_wallet/monero/monero_transaction_history.dart';
import 'package:cake_wallet/monero/monero_transaction_info.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/entities/transaction_direction.dart';
import 'package:cake_wallet/entities/transaction_info.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_display_mode.dart';
import 'package:cake_wallet/view_model/wyre_view_model.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/sync_status.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/dashboard/trade_filter_store.dart';
import 'package:cake_wallet/store/dashboard/transaction_filter_store.dart';
import 'package:cake_wallet/view_model/dashboard/formatted_item_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:convert/convert.dart';

part 'dashboard_view_model.g.dart';

class DashboardViewModel = DashboardViewModelBase with _$DashboardViewModel;

abstract class DashboardViewModelBase with Store {
  DashboardViewModelBase(
      {this.balanceViewModel,
      this.appStore,
      this.tradesStore,
      this.tradeFilterStore,
      this.transactionFilterStore,
      this.settingsStore,
      this.ordersSource,
      this.ordersStore,
      this.wyreViewModel}) {
    filterItems = {
      S.current.transactions: [
        FilterItem(
            value: () => transactionFilterStore.displayIncoming,
            caption: S.current.incoming,
            onChanged: (value) => transactionFilterStore.toggleIncoming()),
        FilterItem(
            value: () => transactionFilterStore.displayOutgoing,
            caption: S.current.outgoing,
            onChanged: (value) => transactionFilterStore.toggleOutgoing()),
        // FilterItem(
        //     value: () => false,
        //     caption: S.current.transactions_by_date,
        //     onChanged: null),
      ],
      S.current.trades: [
        FilterItem(
            value: () => tradeFilterStore.displayXMRTO,
            caption: 'XMR.TO',
            onChanged: (value) => tradeFilterStore
                .toggleDisplayExchange(ExchangeProviderDescription.xmrto)),
        FilterItem(
            value: () => tradeFilterStore.displayChangeNow,
            caption: 'Change.NOW',
            onChanged: (value) => tradeFilterStore
                .toggleDisplayExchange(ExchangeProviderDescription.changeNow)),
        FilterItem(
            value: () => tradeFilterStore.displayMorphToken,
            caption: 'MorphToken',
            onChanged: (value) => tradeFilterStore
                .toggleDisplayExchange(ExchangeProviderDescription.morphToken)),
        FilterItem(
            value: () => tradeFilterStore.displaySideShift,
            caption: 'SideShift.ai',
            onChanged: (value) => tradeFilterStore
                .toggleDisplayExchange(ExchangeProviderDescription.sideshift)),
      ]
    };

    isRunningWebView = false;

    name = appStore.wallet?.name;
    wallet ??= appStore.wallet;
    type = wallet.type;

    _reaction = reaction((_) => appStore.wallet, _onWalletChange);

    final _wallet = wallet;

    if (_wallet is MoneroWallet) {
      subname = _wallet.account?.label;

      _onMoneroAccountChangeReaction = reaction((_) => _wallet.account,
          (Account account) => _onMoneroAccountChange(_wallet));

      _onMoneroBalanceChangeReaction = reaction((_) => _wallet.balance,
          (MoneroBalance balance) => _onMoneroTransactionsUpdate(_wallet));

      final _accountTransactions = _wallet
          .transactionHistory.transactions.values
          .where((tx) => tx.accountIndex == _wallet.account.id)
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

    connectMapToListWithTransform(
        appStore.wallet.transactionHistory.transactions,
        transactions,
        (TransactionInfo val) => TransactionListItem(
            transaction: val,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore),
        filter: (TransactionInfo tx) {
      final wallet = _wallet;
      if (tx is MoneroTransactionInfo && wallet is MoneroWallet) {
        return tx.accountIndex == wallet.account.id;
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
  bool isRunningWebView;

  @computed
  String get address => wallet.address;

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
  WalletBase<Balance> wallet;

  bool get hasRescan => wallet.type == WalletType.monero;

  Box<Order> ordersSource;

  BalanceViewModel balanceViewModel;

  AppStore appStore;

  SettingsStore settingsStore;

  TradesStore tradesStore;

  OrdersStore ordersStore;

  TradeFilterStore tradeFilterStore;

  TransactionFilterStore transactionFilterStore;

  WyreViewModel wyreViewModel;

  Map<String, List<FilterItem>> filterItems;

  bool get isBuyEnabled => settingsStore.isBitcoinBuyEnabled;

  ReactionDisposer _reaction;

  ReactionDisposer _onMoneroAccountChangeReaction;

  ReactionDisposer _onMoneroBalanceChangeReaction;

  Future<void> reconnect() async {
    final node = appStore.settingsStore.getCurrentNode(wallet.type);
    await wallet.connectToNode(node: node);
  }

  @action
  void _onWalletChange(WalletBase<Balance> wallet) {
    this.wallet = wallet;
    type = wallet.type;
    name = wallet.name;

    if (wallet is MoneroWallet) {
      subname = wallet.account?.label;

      _onMoneroAccountChangeReaction?.reaction?.dispose();
      _onMoneroBalanceChangeReaction?.reaction?.dispose();

      _onMoneroAccountChangeReaction = reaction((_) => wallet.account,
          (Account account) => _onMoneroAccountChange(wallet));

      _onMoneroBalanceChangeReaction = reaction((_) => wallet.balance,
          (MoneroBalance balance) => _onMoneroTransactionsUpdate(wallet));

      _onMoneroTransactionsUpdate(wallet);
    } else {
      subname = null;

      transactions.clear();

      transactions.addAll(wallet.transactionHistory.transactions.values.map(
          (transaction) => TransactionListItem(
              transaction: transaction,
              balanceViewModel: balanceViewModel,
              settingsStore: appStore.settingsStore)));
    }

    connectMapToListWithTransform(
        appStore.wallet.transactionHistory.transactions,
        transactions,
            (TransactionInfo val) => TransactionListItem(
            transaction: val,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore),
        filter: (TransactionInfo tx) {
          if (tx is MoneroTransactionInfo && wallet is MoneroWallet) {
            return tx.accountIndex == wallet.account.id;
          }

          return true;
        });
  }

  @action
  void _onMoneroAccountChange(MoneroWallet wallet) {
    subname = wallet.account?.label;
    _onMoneroTransactionsUpdate(wallet);
  }

  @action
  void _onMoneroTransactionsUpdate(MoneroWallet wallet) {
    transactions.clear();

    final _accountTransactions = wallet.transactionHistory.transactions.values
        .where((tx) => tx.accountIndex == wallet.account.id)
        .toList();

    transactions.addAll(_accountTransactions.map((transaction) =>
        TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore)));
  }


}
