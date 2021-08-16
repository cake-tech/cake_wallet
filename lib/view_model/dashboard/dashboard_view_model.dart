import 'package:cake_wallet/core/transaction_history.dart';
import 'package:cake_wallet/entities/balance.dart';
import 'package:cake_wallet/buy/order.dart';
import 'package:cake_wallet/entities/transaction_history.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/monero/account.dart';
import 'package:cake_wallet/monero/monero_balance.dart';
import 'package:cake_wallet/monero/monero_transaction_info.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/transaction_info.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
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
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
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
      this.ordersStore}) {
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
      ]
    };

    name = appStore.wallet?.name;
    wallet ??= appStore.wallet;
    type = wallet.type;
    isOutdatedElectrumWallet =
        wallet.type == WalletType.bitcoin && wallet.seed.split(' ').length < 24;
    final _wallet = wallet;

    if (_wallet is MoneroWallet) {
      subname = _wallet.walletAddresses.account?.label;

      _onMoneroAccountChangeReaction = reaction((_) => _wallet.walletAddresses
          .account, (Account account) => _onMoneroAccountChange(_wallet));

      _onMoneroBalanceChangeReaction = reaction((_) => _wallet.balance,
          (MoneroBalance balance) => _onMoneroTransactionsUpdate(_wallet));

      final _accountTransactions = _wallet
          .transactionHistory.transactions.values
          .where((tx) => tx.accountIndex == _wallet.walletAddresses.account.id)
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
        appStore.wallet.transactionHistory.transactions,
        transactions,
        (TransactionInfo val) => TransactionListItem(
            transaction: val,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore),
        filter: (TransactionInfo tx) {
      final wallet = _wallet;
      if (tx is MoneroTransactionInfo && wallet is MoneroWallet) {
        return tx.accountIndex == wallet.walletAddresses.account.id;
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

  TradesStore tradesStore;

  OrdersStore ordersStore;

  TradeFilterStore tradeFilterStore;

  TransactionFilterStore transactionFilterStore;

  Map<String, List<FilterItem>> filterItems;

  bool get isBuyEnabled => settingsStore.isBitcoinBuyEnabled;

  ReactionDisposer _onMoneroAccountChangeReaction;

  ReactionDisposer _onMoneroBalanceChangeReaction;

  @observable
  bool isOutdatedElectrumWallet;

  Future<void> reconnect() async {
    final node = appStore.settingsStore.getCurrentNode(wallet.type);
    await wallet.connectToNode(node: node);
  }

  @action
  void _onWalletChange(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>,
              TransactionInfo>
          wallet) {
    this.wallet = wallet;
    type = wallet.type;
    name = wallet.name;
    isOutdatedElectrumWallet =
        wallet.type == WalletType.bitcoin && wallet.seed.split(' ').length < 24;

    if (wallet is MoneroWallet) {
      subname = wallet.walletAddresses.account?.label;

      _onMoneroAccountChangeReaction?.reaction?.dispose();
      _onMoneroBalanceChangeReaction?.reaction?.dispose();

      _onMoneroAccountChangeReaction = reaction((_) => wallet.walletAddresses
          .account, (Account account) => _onMoneroAccountChange(wallet));

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
        return tx.accountIndex == wallet.walletAddresses.account.id;
      }

      return true;
    });
  }

  @action
  void _onMoneroAccountChange(MoneroWallet wallet) {
    subname = wallet.walletAddresses.account?.label;
    _onMoneroTransactionsUpdate(wallet);
  }

  @action
  void _onMoneroTransactionsUpdate(MoneroWallet wallet) {
    transactions.clear();

    final _accountTransactions = wallet.transactionHistory.transactions.values
        .where((tx) => tx.accountIndex == wallet.walletAddresses.account.id)
        .toList();

    transactions.addAll(_accountTransactions.map((transaction) =>
        TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore)));
  }
}
