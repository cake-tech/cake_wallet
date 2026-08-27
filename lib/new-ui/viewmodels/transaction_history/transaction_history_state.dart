part of "transaction_history_bloc.dart";

sealed class TransactionHistoryState {
  const TransactionHistoryState();
}

final class TransactionHistoryNotLoaded extends TransactionHistoryState {
  const TransactionHistoryNotLoaded();
}

final class TransactionHistoryLoaded extends TransactionHistoryState {

  TransactionHistoryLoaded({required this.items});

  factory TransactionHistoryLoaded.from(List<HistorySource> sources) {
    final items = [
      for (final source in sources) ...source.relevantItems,
    ]..sort((a, b) => b.date.compareTo(a.date));

    return TransactionHistoryLoaded(items: items);
  }

  final List<HistoryListItem> items;

  List<HistoryListItem> get sectioned => _sectioned ??= formattedItemsList([...items]);
  List<HistoryListItem>? _sectioned;

  bool get isEmpty => items.isEmpty;

  TransactionHistoryLoaded applying(HistorySource source, List<HistoryChange> changes) {
    final newItems = [...items];

    for (final change in changes) {
      switch (change) {
        case HistoryReset():
          break;
        case ItemRemoved(:final id):
          newItems.removeWhere((item) => item.id == id);
        case ItemAdded(:final id):
          newItems.insertAtPoint(source.emitter.byId(id)!);
        case ItemUpdated(:final id):
          newItems.removeWhere((item) => item.id == id);
          newItems.insertAtPoint(source.emitter.byId(id)!);
      }
    }

    return TransactionHistoryLoaded(items: newItems);
  }

}
