import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/src/domain/common/transaction_direction.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';
import 'package:cake_wallet/src/stores/action_list/transaction_list_item.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/store/app_store.dart';

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
    balance = WalletBalace(unlockedBalance: '0.001', totalBalance: '0.005');
    status = SyncedSyncStatus();
    type = WalletType.bitcoin;
    wallet ??= appStore.wallet;
    _reaction = reaction((_) => appStore.wallet, _onWalletChange);
    transactions = ObservableList.of(wallet.transactionHistory.transactions
        .map((transaction) => TransactionListItem(transaction: transaction)));
  }

  @observable
  WalletType type;

  @observable
  String name;

  @computed
  String get address => wallet.address;

  @observable
  WalletBalace balance;

  @observable
  SyncStatus status;

  @observable
  ObservableList<Object> transactions;

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
    balance = WalletBalace(unlockedBalance: '0.001', totalBalance: '0.005');
  }
}
