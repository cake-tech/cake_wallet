import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';

part 'transaction_filter_store.g.dart';

class TransactionFilterStore = TransactionFilterStoreBase
    with _$TransactionFilterStore;

abstract class TransactionFilterStoreBase with Store {
  TransactionFilterStoreBase(
      {this.displayAllTransaction = true, this.displayIncoming = false, this.displayOutgoing = false});

  @observable
  bool displayAllTransaction;

  @observable
  bool displayIncoming;

  @observable
  bool displayOutgoing;

  @observable
  DateTime startDate;

  @observable
  DateTime endDate;

  @action
  void showAllTransaction() {
    displayAllTransaction = !displayAllTransaction;
    if(displayAllTransaction){
      displayIncoming = true;
      displayOutgoing = true;
      return;
    }
    displayIncoming = false;
    displayOutgoing = false;
  }

  @action
  void showIncoming() {
    displayIncoming = true;
    displayOutgoing = false;
  }

  @action
  void showOutgoing() {
    displayOutgoing = true;
    displayIncoming = false;
  }

  @action
  void changeStartDate(DateTime date) => startDate = date;

  @action
  void changeEndDate(DateTime date) => endDate = date;

  List<TransactionListItem> filtered({List<TransactionListItem> transactions}) {
    var _transactions = <TransactionListItem>[];
    final needToFilter = !displayOutgoing ||
        !displayIncoming ||
        (startDate != null && endDate != null);

    if (needToFilter) {
      _transactions = transactions.where((item) {
        var allowed = true;

        if (allowed && startDate != null && endDate != null) {
          allowed = startDate.isBefore(item.transaction.date) &&
              endDate.isAfter(item.transaction.date);
        }

        if (allowed && (!displayOutgoing || !displayIncoming)) {
          allowed = (displayOutgoing &&
              item.transaction.direction ==
                  TransactionDirection.outgoing) ||
              (displayIncoming &&
                  item.transaction.direction == TransactionDirection.incoming);
        }

        return allowed;
      }).toList();
    } else {
      _transactions = transactions;
    }

    return _transactions;
  }
}