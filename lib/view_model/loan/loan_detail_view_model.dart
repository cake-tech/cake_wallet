import 'package:cake_wallet/view_model/loan/loan_item.dart';
import 'package:mobx/mobx.dart';
part 'loan_detail_view_model.g.dart';

class LoanDetailViewModel = LoanDetailViewModelBase with _$LoanDetailViewModel;

abstract class LoanDetailViewModelBase with Store {
  LoanDetailViewModelBase({LoanItem loanItem}) {
    loanDetails = loanItem;
  }

  LoanItem loanDetails;
}
