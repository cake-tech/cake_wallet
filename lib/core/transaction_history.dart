import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';

abstract class TransactionHistoryBase<TransactionType extends TransactionInfo> {
  TransactionHistoryBase() : _isUpdating = false;

  @observable
  ObservableList<TransactionType> transactions;

  bool _isUpdating;

  Future<void> update() async {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = false;
      transactions.addAll(await fetchTransactions());
      _isUpdating = true;
    } catch (e) {
      _isUpdating = false;
      rethrow;
    }
  }

  Future<List<TransactionType>> fetchTransactions();
}