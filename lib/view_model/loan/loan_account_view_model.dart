import 'package:cake_wallet/view_model/loan/loan_item.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
part 'loan_account_view_model.g.dart';

class LoanAccountViewModel = LoanAccountViewModelBase
    with _$LoanAccountViewModel;

abstract class LoanAccountViewModelBase with Store {
  LoanAccountViewModelBase({@required this.wallet}) {
    isLoggedIn = false;
    _fetchLoanItems();
  }

  final WalletBase wallet;

  @computed
  bool get status => wallet.syncStatus is SyncedSyncStatus;

  @observable
  bool isLoggedIn;

  @observable
  List<LoanItem> items;

  Future<void> _fetchLoanItems() async {
    await Future<void>.delayed(Duration(seconds: 5));
    isLoggedIn = true;
    items = [
      LoanItem(id: '2133432', amount: 20000, status: 'Awaiting deposit'),
      LoanItem(id: '2133432', amount: 20000, status: 'Awaiting deposit'),
      LoanItem(id: '2133432', amount: 20000, status: 'Awaiting deposit')
    ];
  }
}
