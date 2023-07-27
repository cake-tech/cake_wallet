import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_info.dart';

abstract class TransactionHistoryBase<TransactionType extends TransactionInfo> {
  TransactionHistoryBase()
    : transactions = ObservableMap<String, TransactionType>();

  @observable
  ObservableMap<String, TransactionType> transactions;

  Future<void> save();

  void addOne(TransactionType transaction);

  void addMany(Map<String, TransactionType> transactions);

  void clear() => transactions.clear();

  // bool _isUpdating;

  // @action
  // Future<void> update() async {
  //   if (_isUpdating) {
  //     return;
  //   }

  //   try {
  //     _isUpdating = true;
  //     final _transactions = await fetchTransactions();
  //     transactions.keys
  //         .toSet()
  //         .difference(_transactions.keys.toSet())
  //         .forEach((k) => transactions.remove(k));
  //     _transactions.forEach((key, value) => transactions[key] = value);
  //     _isUpdating = false;
  //   } catch (e) {
  //     _isUpdating = false;
  //     rethrow;
  //   }
  // }

  // void updateAsync({void Function() onFinished}) {
  //   fetchTransactionsAsync(
  //       (transaction) => transactions[transaction.id] = transaction,
  //       onFinished: onFinished);
  // }

  // void fetchTransactionsAsync(
  //     void Function(TransactionType transaction) onTransactionLoaded,
  //     {void Function() onFinished});

  // Future<Map<String, TransactionType>> fetchTransactions();
}
