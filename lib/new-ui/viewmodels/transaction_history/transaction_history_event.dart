part of "transaction_history_bloc.dart";

sealed class TransactionHistoryEvent {
  const TransactionHistoryEvent();
}

/// A batch of changes from one source. One event type and one queue, because
/// these are deltas that have to be applied in the order they were produced.
final class TransactionHistoryChanged extends TransactionHistoryEvent {
  const TransactionHistoryChanged(this.source, this.journal);

  final HistorySource source;
  final List<HistoryChange> journal;
}

/// Rebuild from every source as it stands now.
///
/// Fired when something outside the sources changes what belongs in the list —
/// leaving the filter page, or switching wallet or account. There is no
/// incremental path: a filter change alters every row's relevance at once.
final class TransactionHistoryRefreshed extends TransactionHistoryEvent {
  const TransactionHistoryRefreshed();
}
