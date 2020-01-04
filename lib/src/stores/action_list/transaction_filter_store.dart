import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/transaction_direction.dart';
import 'package:cake_wallet/src/stores/action_list/transaction_list_item.dart';

part 'transaction_filter_store.g.dart';

class TransactionFilterStore = TransactionFilterStoreBase
    with _$TransactionFilterStore;

abstract class TransactionFilterStoreBase with Store {
  @observable
  bool displayIncoming;

  @observable
  bool displayOutgoing;

  @observable
  DateTime startDate;

  @observable
  DateTime endDate;

  TransactionFilterStoreBase(
      {this.displayIncoming = true, this.displayOutgoing = true});

  @action
  void toggleIncoming() => displayIncoming = !displayIncoming;

  @action
  void toggleOutgoing() => displayOutgoing = !displayOutgoing;

  @action
  void changeStartDate(DateTime date) => startDate = date;

  @action
  void changeEndDate(DateTime date) => endDate = date;

  List<TransactionListItem> filtered({List<TransactionListItem> transactions}) {
    List<TransactionListItem> _transactions = [];
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
