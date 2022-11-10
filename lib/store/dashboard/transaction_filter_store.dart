import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'transaction_filter_store.g.dart';

class TransactionFilterStore = TransactionFilterStoreBase
    with _$TransactionFilterStore;

abstract class TransactionFilterStoreBase with Store {
  TransactionFilterStoreBase();

  Observable<bool> displayAll = Observable(true);
  Observable<bool> displayIncoming = Observable(true);
  Observable<bool> displayOutgoing = Observable(true);

  @observable
  DateTime? startDate;

  @observable
  DateTime? endDate;

  @action
  void toggleIAll() {
    displayAll.value = (!displayAll.value);
    if (displayAll.value) {
      displayOutgoing.value = true;
      displayIncoming.value = true;
    }
    if (!displayAll.value) {
      displayOutgoing.value = false;
      displayIncoming.value = false;
    }
  }

  @action
  void toggleIncoming() {
    displayIncoming.value = (!displayIncoming.value);
    if (displayIncoming.value && displayOutgoing.value) {
      displayAll.value = true;
    }
    if (!displayIncoming.value || !displayOutgoing.value) {
      displayAll.value = false;
    }
  }


  @action
  void toggleOutgoing() {
    displayOutgoing.value = (!displayOutgoing.value);
    if (displayIncoming.value && displayOutgoing.value) {
      displayAll.value = true;
    }
    if (!displayIncoming.value || !displayOutgoing.value) {
      displayAll.value = false;
    }
  }

  @action
  void changeStartDate(DateTime date) => startDate = date;

  @action
  void changeEndDate(DateTime date) => endDate = date;

  List<TransactionListItem> filtered({required List<TransactionListItem> transactions}) {
    var _transactions = <TransactionListItem>[];
    final needToFilter = !displayOutgoing.value ||
        !displayIncoming.value ||
        (startDate != null && endDate != null);

    if (needToFilter) {
      _transactions = transactions.where((item) {
        var allowed = true;

        if (allowed && startDate != null && endDate != null) {
          allowed = (startDate?.isBefore(item.transaction.date) ?? false)
              && (endDate?.isAfter(item.transaction.date) ?? false);
        }

        if (allowed && (!displayOutgoing.value || !displayIncoming.value)) {
          allowed = (displayOutgoing.value &&
              item.transaction.direction ==
                  TransactionDirection.outgoing) ||
              (displayIncoming.value &&
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