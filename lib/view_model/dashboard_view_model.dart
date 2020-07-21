import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/src/domain/common/transaction_direction.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';
import 'package:cake_wallet/src/stores/action_list/transaction_list_item.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'dashboard_view_model.g.dart';

class DashboardViewModel = DashboardViewModelBase with _$DashboardViewModel;

class WalletBalace {
  WalletBalace({this.unlockedBalance, this.totalBalance});

  final String unlockedBalance;
  final String totalBalance;
}

abstract class DashboardViewModelBase with Store {
  DashboardViewModelBase({this.appStore}) {
    name = appStore.wallet?.name;
    wallet ??= appStore.wallet;
    type = wallet.type;
    transactions = ObservableList.of(wallet.transactionHistory.transactions
        .map((transaction) => TransactionListItem(transaction: transaction)));
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
  WalletBalace get balance {
    final wallet = this.wallet;

    if (wallet is MoneroWallet) {
      return WalletBalace(
          unlockedBalance: wallet.balance.formattedUnlockedBalance,
          totalBalance: wallet.balance.formattedFullBalance);
    }

    if (wallet is BitcoinWallet) {
      return WalletBalace(
          unlockedBalance: wallet.balance.confirmedFormatted,
          totalBalance: wallet.balance.unconfirmedFormatted);
    }
  }

  @observable
  ObservableList<Object> transactions;
//  ObservableList.of([
//    TransactionListItem(transaction: BitcoinTransactionInfo(
//      id: '',
//      height: 0,
//      amount: 0,
//      direction: TransactionDirection.incoming,
//      date: DateTime.now(),
//      isPending: false
//    )),
//    TransactionListItem(transaction: BitcoinTransactionInfo(
//        id: '',
//        height: 0,
//        amount: 0,
//        direction: TransactionDirection.incoming,
//        date: DateTime.now(),
//        isPending: false
//    )),
//    TransactionListItem(transaction: BitcoinTransactionInfo(
//        id: '',
//        height: 0,
//        amount: 0,
//        direction: TransactionDirection.incoming,
//        date: DateTime.now(),
//        isPending: false
//    )),
//    TransactionListItem(transaction: BitcoinTransactionInfo(
//        id: '',
//        height: 0,
//        amount: 0,
//        direction: TransactionDirection.incoming,
//        date: DateTime.now(),
//        isPending: false
//    )),
//    TransactionListItem(transaction: BitcoinTransactionInfo(
//        id: '',
//        height: 0,
//        amount: 0,
//        direction: TransactionDirection.incoming,
//        date: DateTime.now(),
//        isPending: false
//    )),
//    TransactionListItem(transaction: BitcoinTransactionInfo(
//        id: '',
//        height: 0,
//        amount: 0,
//        direction: TransactionDirection.incoming,
//        date: DateTime.now(),
//        isPending: false
//    )),
//    TransactionListItem(transaction: BitcoinTransactionInfo(
//        id: '',
//        height: 0,
//        amount: 0,
//        direction: TransactionDirection.incoming,
//        date: DateTime.now(),
//        isPending: false
//    )),
//    TransactionListItem(transaction: BitcoinTransactionInfo(
//        id: '',
//        height: 0,
//        amount: 0,
//        direction: TransactionDirection.incoming,
//        date: DateTime.now(),
//        isPending: false
//    )),
//    TransactionListItem(transaction: BitcoinTransactionInfo(
//        id: '',
//        height: 0,
//        amount: 0,
//        direction: TransactionDirection.incoming,
//        date: DateTime.now(),
//        isPending: false
//    )),
//    TransactionListItem(transaction: BitcoinTransactionInfo(
//        id: '',
//        height: 0,
//        amount: 0,
//        direction: TransactionDirection.incoming,
//        date: DateTime.now(),
//        isPending: false
//    )),
//  ]);

  @observable
  String subname;

  WalletBase wallet;

  AppStore appStore;

  ReactionDisposer _reaction;

  void _onWalletChange(WalletBase wallet) {
    name = wallet.name;
    transactions.clear();
    transactions.addAll(wallet.transactionHistory.transactions
        .map((transaction) => TransactionListItem(transaction: transaction)));
  }
}
