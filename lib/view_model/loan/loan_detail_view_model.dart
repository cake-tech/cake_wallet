import 'package:cake_wallet/view_model/loan/loan_item.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';
part 'loan_detail_view_model.g.dart';

class LoanDetailViewModel = LoanDetailViewModelBase with _$LoanDetailViewModel;

abstract class LoanDetailViewModelBase with Store {
  LoanDetailViewModelBase({
    LoanItem loanItem,
    this.wallet,
  }) {
    loanDetails = loanItem;
  }

  @observable
  LoanItem loanDetails;

  final WalletBase wallet;

  bool isLoan = true;

  @computed
  bool get status => wallet.syncStatus is SyncedSyncStatus;
}
