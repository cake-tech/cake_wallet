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

final class TransactionHistoryFilterToggled extends TransactionHistoryEvent {
  const TransactionHistoryFilterToggled(this.filter);

  final HistoryFilter filter;
}

final class TransactionHistoryFiltersSet extends TransactionHistoryEvent {
  const TransactionHistoryFiltersSet(this.filters, {required this.value});

  final List<HistoryFilter> filters;
  final bool value;
}

final class TransactionHistoryAllFiltersToggled extends TransactionHistoryEvent {
  const TransactionHistoryAllFiltersToggled({required this.value});

  final bool value;
}
