part of "transaction_history_bloc.dart";

sealed class TransactionHistoryState {
  const TransactionHistoryState();
}

/// Nothing to show yet: no source has finished its first load. Distinct from a
/// loaded-but-empty history, which renders the empty message.
final class TransactionHistoryNotLoaded extends TransactionHistoryState {
  const TransactionHistoryNotLoaded();
}

final class TransactionHistoryLoaded extends TransactionHistoryState {
  TransactionHistoryLoaded({required this.items, required this.owners});

  /// Every source's rows merged, sorted newest first, with no date section
  /// markers — callers that don't want sections never pay for them.
  final List<ActionListItem> items;

  /// Item id to the precedence of the source that currently owns it. This is
  /// what lets a payjoin row displace the transaction row with the same id.
  final Map<String, int> owners;

  /// [items] with date section markers woven in, computed once per state.
  /// Safe to cache unconditionally: this state is never mutated.
  List<ActionListItem> get sectioned => _sectioned ??= formattedItemsList([...items]);
  List<ActionListItem>? _sectioned;

  bool get isEmpty => items.isEmpty;

  /// Builds from scratch, letting the highest-precedence source win each id.
  factory TransactionHistoryLoaded.from(List<HistorySource> sources) {
    final items = <ActionListItem>[];
    final owners = <String, int>{};

    // Descending precedence, so the first claim on an id is the winning one.
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

  /// Applies one source's journal of deltas.
  ///
  /// The source is authoritative for its own ids only — a change from a
  /// lower-precedence source cannot dislodge a row a higher one owns.
  TransactionHistoryLoaded applying(HistorySource source, List<HistoryChange> journal) {
    // A pointer copy: the costly part was projecting and sorting, and neither
    // happens here.
    final next = [...items];
    final nextOwners = {...owners};

    for (final change in journal) {
      switch (change) {
        // The bloc rebuilds wholesale for these rather than applying them.
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
    List<ActionListItem> list,
    Map<String, int> owners,
    HistorySource source,
    String id,
  ) {
    final item = source.emitter.byId(id);

    // Gone, or filtered out: it must not be in the list, but only this source's
    // own rows are ours to withdraw.
    if (item == null || !source.filters.relevant(item)) {
      if (owners[id] == source.precedence) {
        _removeById(list, id);
        owners.remove(id);
      }
      return;
    }

    final owner = owners[id];

    if (owner != null && owner > source.precedence) {
      // A higher-precedence source is showing this id instead.
      return;
    }

    if (owner != null && owner == source.precedence) {
      _removeById(list, id);
    } else if (owner != null) {
      // Taking over from a lower-precedence source.
      _removeById(list, id);
    }

    owners[id] = source.precedence;
    list.insert(list.insertionPoint(item.date), item);
  }

  static void _removeById(List<ActionListItem> list, String id) {
    final index = list.indexWhere((item) => item.id == id);
    if (index >= 0) {
      list.removeAt(index);
    }
  }
}
