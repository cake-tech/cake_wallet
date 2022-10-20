import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';

part 'transaction_filter_store.g.dart';

class TransactionFilterStore = TransactionFilterStoreBase
    with _$TransactionFilterStore;

abstract class TransactionFilterStoreBase with Store {
  TransactionFilterStoreBase(
      {this.displayIncoming = true, this.displayOutgoing = true});

  @observable
  bool displayIncoming;

  @observable
  bool displayOutgoing;

  @observable
  DateTime? startDate;

  @observable
  DateTime? endDate;

  @action
  void toggleIncoming() => displayIncoming = !displayIncoming;

  @action
  void toggleOutgoing() => displayOutgoing = !displayOutgoing;

  @action
  void changeStartDate(DateTime date) => startDate = date;

  @action
  void changeEndDate(DateTime date) => endDate = date;

  List<TransactionListItem> filtered({required List<TransactionListItem> transactions}) {
    var _transactions = <TransactionListItem>[];
    final needToFilter = !displayOutgoing ||
        !displayIncoming ||
        (startDate != null && endDate != null);

    if (needToFilter) {
      _transactions = transactions.where((item) {
        var allowed = true;

        if (allowed && startDate != null && endDate != null) {
          allowed = (startDate?.isBefore(item.transaction.date) ?? false)
              && (endDate?.isAfter(item.transaction.date) ?? false);
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