part of "transaction_history_bloc.dart";

sealed class TransactionHistoryEvent {
  const TransactionHistoryEvent();
}

final class TransactionHistoryChanged extends TransactionHistoryEvent {
  const TransactionHistoryChanged(this.source, this.journal);

  final HistorySource source;
  final List<HistoryChange> journal;
}


final class TransactionHistoryRefreshed extends TransactionHistoryEvent {
  const TransactionHistoryRefreshed();
}
