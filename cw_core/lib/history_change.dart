sealed class HistoryChange {
  const HistoryChange();
}

final class ItemAdded extends HistoryChange {
  const ItemAdded(this.id);

  final String id;
}

final class ItemUpdated extends HistoryChange {
  const ItemUpdated(this.id);

  final String id;
}

final class ItemRemoved extends HistoryChange {
  const ItemRemoved(this.id);

  final String id;
}

abstract class HistoryReset extends HistoryChange {
  const HistoryReset();
}

final class HistoryLoaded extends HistoryReset {
  const HistoryLoaded();
}

final class HistoryCleared extends HistoryReset {
  const HistoryCleared();
}
