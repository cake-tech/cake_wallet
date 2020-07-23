import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/transaction_direction.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_display_mode.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/dashboard/trade_filter_store.dart';
import 'package:cake_wallet/store/dashboard/transaction_filter_store.dart';
import 'package:cake_wallet/view_model/dashboard/formatted_item_list.dart';

part 'dashboard_view_model.g.dart';

class DashboardViewModel = DashboardViewModelBase with _$DashboardViewModel;

abstract class DashboardViewModelBase with Store {
  DashboardViewModelBase({
    this.balanceViewModel,
    this.appStore,
    this.tradesStore,
    this.tradeFilterStore,
    this.transactionFilterStore}) {

    name = appStore.wallet?.name;
    wallet ??= appStore.wallet;
    type = wallet.type;

    transactions = ObservableList.of(wallet.transactionHistory.transactions
        .map((transaction) => TransactionListItem(
        transaction: transaction,
        price: price,
        fiatCurrency: appStore.settingsStore.fiatCurrency,
        displayMode: balanceDisplayMode)));

    _reaction = reaction((_) => appStore.wallet, _onWalletChange);

    final _wallet = wallet;

    if (_wallet is MoneroWallet) {
      subname = _wallet.account?.label;
    }

    currentPage = 0;
  }

  @observable
  WalletType type;

  @observable
  String name;

  @observable
  double currentPage;

  @observable
  ObservableList<TransactionListItem> transactions;

  @observable
  String subname;

  @computed
  String get address => wallet.address;

  @computed
  SyncStatus get status => wallet.syncStatus;

  @computed
  String get syncStatusText {
    var statusText = '';

    if (status is SyncingSyncStatus) {
      statusText = S.current
          .Blocks_remaining(
          status.toString());
    }

    if (status is FailedSyncStatus) {
      statusText = S
          .current
          .please_try_to_connect_to_another_node;
    }

    return statusText;
  }

  @computed
  BalanceDisplayMode get balanceDisplayMode =>
      appStore.settingsStore.balanceDisplayMode;

  @computed
  List<TradeListItem> get trades => tradesStore.trades;

  @computed
  double get price => balanceViewModel.price;

  @computed
  List<ActionListItem> get items {
    final _items = <ActionListItem>[];

    _items
        .addAll(transactionFilterStore.filtered(transactions: transactions));
    _items.addAll(tradeFilterStore.filtered(trades: trades));

    return formattedItemsList(_items);
  }

  WalletBase wallet;

  BalanceViewModel balanceViewModel;

  AppStore appStore;

  TradesStore tradesStore;

  TradeFilterStore tradeFilterStore;

  TransactionFilterStore transactionFilterStore;

  ReactionDisposer _reaction;

  void _onWalletChange(WalletBase wallet) {
    name = wallet.name;
    transactions.clear();
    transactions.addAll(wallet.transactionHistory.transactions
        .map((transaction) => TransactionListItem(
        transaction: transaction,
        price: price,
        fiatCurrency: appStore.settingsStore.fiatCurrency,
        displayMode: balanceDisplayMode)));
  }
}
