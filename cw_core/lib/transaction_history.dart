import "dart:async";
import "dart:collection";

import "package:cw_core/history_change.dart";
import "package:cw_core/transaction_info.dart";
import "package:meta/meta.dart";

export "package:cw_core/history_change.dart";

abstract class TransactionHistory<TransactionType extends TransactionInfo> {
  TransactionHistory();

  final Map<String, TransactionType> _transactions = {};
  final StreamController<HistoryChange> _changes = StreamController<HistoryChange>.broadcast();

  Map<String, TransactionType> get transactions => UnmodifiableMapView(_transactions);

  Stream<HistoryChange> get changes => _changes.stream;

  bool get hasLoaded => _hasLoaded;
  bool _hasLoaded = false;

  void markLoaded() {
    if (_hasLoaded) {
      return;
    }
    _hasLoaded = true;
    _emit(const HistoryLoaded());
  }

  void addOne(TransactionType transaction) => put(transaction.id, transaction);

  void addMany(Map<String, TransactionType> transactions) => transactions.forEach(put);

  void remove(String id) => takeOut(id);

  void removeWhere(bool Function(String id, TransactionType transaction) test) {
    final toRemove = [
      for (final entry in _transactions.entries)
        if (test(entry.key, entry.value)) entry.key,
    ];
    toRemove.forEach(takeOut);
  }

  void clear() {
    if (_transactions.isEmpty) {
      return;
    }
    _transactions.clear();
    _emit(const HistoryCleared());
  }

  void markUpdated(Iterable<String> ids) {
    for (final id in ids) {
      if (_transactions.containsKey(id)) {
        _emit(ItemUpdated(id));
      }
    }
  }

  @protected
  void put(String id, TransactionType transaction) {
    final existed = _transactions.containsKey(id);
    _transactions[id] = transaction;
    _emit(existed ? ItemUpdated(id) : ItemAdded(id));
  }

  @protected
  void takeOut(String id) {
    if (_transactions.remove(id) != null) {
      _emit(ItemRemoved(id));
    }
  }

  void _emit(HistoryChange change) {
    if (!_changes.isClosed) {
      _changes.add(change);
    }
  }

  Future<void> dispose() => _changes.close();
}

abstract class SavableTransactionHistory<TransactionType extends TransactionInfo>
    extends TransactionHistory<TransactionType> {
  Future<void> save();
}
