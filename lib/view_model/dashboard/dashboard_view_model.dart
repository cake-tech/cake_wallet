import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/store/anonpay/anonpay_transactions_store.dart';
import 'package:cake_wallet/view_model/dashboard/anonpay_transaction_list_item.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/balance.dart';
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
      required this.ordersStore,
      required this.transactionDescriptionBox,
      required this.anonpayTransactionsStore})
  : isOutdatedElectrumWallet = false,
    hasSellAction = false,
    hasBuyAction = false,
    hasExchangeAction = false,
    isShowFirstYatIntroduction = false,
    isShowSecondYatIntroduction = false,
    isShowThirdYatIntroduction = false,
    filterItems = {
      S.current.transactions: [
        FilterItem(
            value: () => transactionFilterStore.displayAll,
            caption: S.current.all_transactions,
            onChanged:  transactionFilterStore.toggleAll),
        FilterItem(
            value: () => transactionFilterStore.displayIncoming,
            caption: S.current.incoming,
            onChanged:transactionFilterStore.toggleIncoming),
        FilterItem(
            value: () => transactionFilterStore.displayOutgoing,
            caption: S.current.outgoing,
            onChanged: transactionFilterStore.toggleOutgoing),
        // FilterItem(
        //     value: () => false,
        //     caption: S.current.transactions_by_date,
        //     onChanged: null),
      ],
      S.current.trades: [
        FilterItem(
            value: () => tradeFilterStore.displayAllTrades,
            caption: S.current.all_trades,
            onChanged: () => tradeFilterStore
                .toggleDisplayExchange(ExchangeProviderDescription.all)),
        FilterItem(
            value: () => tradeFilterStore.displayChangeNow,
            caption: ExchangeProviderDescription.changeNow.title,
            onChanged: () => tradeFilterStore
                .toggleDisplayExchange(ExchangeProviderDescription.changeNow)),
        FilterItem(
            value: () => tradeFilterStore.displaySideShift,
            caption: ExchangeProviderDescription.sideShift.title,
            onChanged: () => tradeFilterStore
                .toggleDisplayExchange(ExchangeProviderDescription.sideShift)),
        FilterItem(
            value: () => tradeFilterStore.displaySimpleSwap,
            caption: ExchangeProviderDescription.simpleSwap.title,
            onChanged: () => tradeFilterStore
                .toggleDisplayExchange(ExchangeProviderDescription.simpleSwap)),
        FilterItem(
            value: () => tradeFilterStore.displayTrocador,
            caption: ExchangeProviderDescription.trocador.title,
            onChanged: () => tradeFilterStore
                .toggleDisplayExchange(ExchangeProviderDescription.trocador)),
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


   reaction((_) => settingsStore.fiatCurrency,
            (FiatCurrency fiatCurrency) {
          _wallet.transactionHistory.transactions.values.forEach((tx) {
            _getHistoricalFiatRate(tx);
          });
        });

    reaction((_) => settingsStore.fiatApiMode,
            (FiatApiMode fiatApiMode) {
          _wallet.transactionHistory.transactions.values.forEach((tx) {
            _getHistoricalFiatRate(tx);
          });
        });


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

      transactions = ObservableList.of(_accountTransactions.map((transaction) {


          _getHistoricalFiatRate(transaction);

        return TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            settingsStore: appStore.settingsStore);
      }));
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

          _wallet.transactionHistory.transactions.values.forEach((tx) {
            _getHistoricalFiatRate(tx);
          });

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
  bool get shouldShowMarketPlaceInDashboard {
    return appStore.settingsStore.shouldShowMarketPlaceInDashboard;
  }

  @computed
  List<TradeListItem> get trades => tradesStore.trades
      .where((trade) => trade.trade.walletId == wallet.id)
      .toList();

  @computed
  List<OrderListItem> get orders => ordersStore.orders
      .where((item) => item.order.walletId == wallet.id)
      .toList();

  @computed
  List<AnonpayTransactionListItem> get anonpayTransactons => anonpayTransactionsStore.transactions
      .where((item) => item.transaction.walletId == wallet.id)
      .toList();

  @computed
  double get price => balanceViewModel.price;

  @computed
  List<ActionListItem> get items {
    final _items = <ActionListItem>[];

    _items.addAll(transactionFilterStore.filtered(transactions: [...transactions, ...anonpayTransactons]));
    _items.addAll(tradeFilterStore.filtered(trades: trades, wallet: wallet));
    _items.addAll(orders);

    return formattedItemsList(_items);
  }

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>
      wallet;

  bool get hasRescan => wallet.type == WalletType.monero || wallet.type == WalletType.haven;

  BalanceViewModel balanceViewModel;

  AppStore appStore;

  SettingsStore settingsStore;

  YatStore yatStore;

  TradesStore tradesStore;

  OrdersStore ordersStore;

  TradeFilterStore tradeFilterStore;

  AnonpayTransactionsStore anonpayTransactionsStore;

  TransactionFilterStore transactionFilterStore;

  Map<String, List<FilterItem>> filterItems;

  final Box<TransactionDescription> transactionDescriptionBox;

  bool get isBuyEnabled => settingsStore.isBitcoinBuyEnabled;

  bool get shouldShowYatPopup => settingsStore.shouldShowYatPopup;

  @action
  void furtherShowYatPopup(bool shouldShow) =>
      settingsStore.shouldShowYatPopup = shouldShow;

  @computed
  bool get isEnabledExchangeAction => settingsStore.exchangeStatus != ExchangeApiMode.disabled;

  @observable
  bool hasExchangeAction;

  @computed
  bool get isEnabledBuyAction =>
      !settingsStore.disableBuy && wallet.type != WalletType.haven;

  @observable
  bool hasBuyAction;

  @computed
  bool get isEnabledSellAction =>
      !settingsStore.disableSell &&
      wallet.type != WalletType.haven &&
      wallet.type != WalletType.monero &&
      wallet.type != WalletType.litecoin;

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

    wallet.transactionHistory.transactions.values.forEach((tx) {
      _getHistoricalFiatRate(tx);
    });


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
    hasBuyAction = !isHaven;
    hasSellAction = !isHaven;
  }

  Future<void> _getHistoricalFiatRate(TransactionInfo transactionInfo) async {
    if (FiatApiMode.disabled == settingsStore.fiatApiMode) return;
    final description = getTransactionDescription(transactionInfo);

    if (description.historicalFiat != settingsStore.fiatCurrency.toString()
        || description.historicalFiatRate == null) {
      if (description.key == 0) description.delete();
      description.historicalFiatRate = null;
      transactionDescriptionBox.put(description.id, description);
      final fiat = settingsStore.fiatCurrency;

      final historicalFiatRate = await FiatConversionService.fetchHistoricalPrice(
          crypto: wallet.currency,
          fiat: fiat,
          torOnly: settingsStore.fiatApiMode == FiatApiMode.torOnly,
          date: transactionInfo.date);
      var formattedFiatAmount = 0.0;
      switch (wallet.type) {
        case WalletType.bitcoin:
        case WalletType.litecoin:
          formattedFiatAmount = bitcoinAmountToDouble(amount: transactionInfo.amount);
          break;
        case WalletType.monero:
        case WalletType.haven:
          formattedFiatAmount = moneroAmountToDouble(amount: transactionInfo.amount);
          break;
        default:
          formattedFiatAmount;
      }
      description.historicalFiatRaw = settingsStore.fiatCurrency.toString();

      if (historicalFiatRate != null) {
        final historicalFiatAmountFormatted = formattedFiatAmount * historicalFiatRate;
        if (description.key == 0) description.delete();
          description.historicalFiatRate = historicalFiatAmountFormatted;
          transactionDescriptionBox.put(description.id, description);
      } else {
        if (description.key == 0) description.delete();
        description.historicalFiatRate = null;
        transactionDescriptionBox.put(description.id, description);
      }
    }
  }

  TransactionDescription getTransactionDescription(TransactionInfo transactionInfo) =>
      transactionDescriptionBox.values.firstWhere((val) => val.id == transactionInfo.id,
          orElse: () => TransactionDescription(id: transactionInfo.id));
}
