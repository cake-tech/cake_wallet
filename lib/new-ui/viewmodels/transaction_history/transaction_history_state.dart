part of "transaction_history_bloc.dart";

sealed class TransactionHistoryState {
  const TransactionHistoryState();
}

final class TransactionHistoryNotLoaded extends TransactionHistoryState {
  const TransactionHistoryNotLoaded();
}

final class TransactionHistoryLoaded extends TransactionHistoryState {
  TransactionHistoryLoaded({required this.items, required this.owners});

  final List<HistoryListItem> items;

  final Map<String, int> owners;

  List<HistoryListItem> get sectioned => _sectioned ??= formattedItemsList([...items]);
  List<HistoryListItem>? _sectioned;

  bool get isEmpty => items.isEmpty;

  factory TransactionHistoryLoaded.from(List<HistorySource> sources) {
    final items = <HistoryListItem>[];
    final owners = <String, int>{};

    final ordered = [...sources]..sort((a, b) => b.precedence.compareTo(a.precedence));

    for (final source in ordered) {
      for (final item in source.relevantItems) {
        if (owners.containsKey(item.id)) {
          continue;
        }
        owners[item.id] = source.precedence;
        items.add(item);
      }
    }

    items.sort((a, b) => b.date.compareTo(a.date));

    return TransactionHistoryLoaded(items: items, owners: owners);
  }

  TransactionHistoryLoaded applying(HistorySource source, List<HistoryChange> journal) {
    final next = [...items];
    final nextOwners = {...owners};

    for (final change in journal) {
      switch (change) {
        case HistoryReset():
          break;
        case ItemRemoved(:final id):
          if (nextOwners[id] == source.precedence) {
            _removeById(next, id);
            nextOwners.remove(id);
          }
        case ItemAdded(:final id):
        case ItemUpdated(:final id):
          _upsert(next, nextOwners, source, id);
      }
    }

    return TransactionHistoryLoaded(items: next, owners: nextOwners);
  }

  static void _upsert(
    List<HistoryListItem> list,
    Map<String, int> owners,
    HistorySource source,
    String id,
  ) {
    final item = source.emitter.byId(id);

    if (item == null || !source.filters.relevant(item)) {
      if (owners[id] == source.precedence) {
        _removeById(list, id);
        owners.remove(id);
      }
      return;
    }

    final owner = owners[id];

    if (owner != null && owner > source.precedence) {
      return;
    }

    if (owner != null && owner == source.precedence) {
      _removeById(list, id);
    } else if (owner != null) {
      _removeById(list, id);
    }

    owners[id] = source.precedence;
    list.insert(list.insertionPoint(item.date), item);
  }

  static void _removeById(List<HistoryListItem> list, String id) {
    final index = list.indexWhere((item) => item.id == id);
    if (index >= 0) {
      list.removeAt(index);
    }
  }
}
