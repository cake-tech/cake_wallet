import "package:cw_core/transaction_info.dart";
import "package:mobx/mobx.dart";

abstract class TransactionHistoryBase<TransactionType extends TransactionInfo> {
  TransactionHistoryBase() : _transactions = ObservableMap<String, TransactionType>() {
    _observeTransactions(_transactions);
  }

  ObservableMap<String, TransactionType> _transactions;
  Dispose? _disposeTransactionsObserver;

  final Map<String, int> _revisions = {};
  final Expando<int> _revisionOfStoredObject = Expando<int>();

  ObservableMap<String, TransactionType> get transactions => _transactions;

  set transactions(ObservableMap<String, TransactionType> value) {
    _disposeTransactionsObserver?.call();
    _transactions = value;
    _observeTransactions(value);
    value.forEach(_recordStored);
  }

  int revisionOf(String id) => _revisions[id] ?? 0;

  int revisionOfStoredObject(TransactionType transaction) =>
      _revisionOfStoredObject[transaction] ?? 0;

  Future<void> save();

  void addOne(TransactionType transaction);

  void addMany(Map<String, TransactionType> transactions);

  void clear() => transactions.clear();

  // Runs before mobx notifies reactions, so the new revision is in place when a reaction reads it.
  void _observeTransactions(ObservableMap<String, TransactionType> map) {
    _disposeTransactionsObserver = map.observe((change) {
      if (change.type == OperationType.remove) {
        return;
      }
      _recordStored(change.key!, change.newValue!);
    });
  }

  void _recordStored(String id, TransactionType transaction) {
    final revision = revisionOf(id) + 1;
    _revisions[id] = revision;
    _revisionOfStoredObject[transaction] = revision;
  }
}
