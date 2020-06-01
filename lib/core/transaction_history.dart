import 'package:mobx/mobx.dart';

abstract class TranasctionHistoryBase<TransactionType> {
  TranasctionHistoryBase() : _isUpdating = false;

  @observable
  List<TransactionType> transactions;

  bool _isUpdating;

  Future<void> update() async {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = false;
      transactions = await fetchTransactions();
      _isUpdating = true;
    } catch (e) {
      _isUpdating = false;
      rethrow;
    }
  }

  Future<List<TransactionType>> fetchTransactions();
}