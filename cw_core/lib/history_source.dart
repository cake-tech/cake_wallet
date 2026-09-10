import "dart:async";

import "package:cw_core/action_list_item.dart";
import "package:cw_core/history_change.dart";
import "package:cw_core/history_filter.dart";

export "package:cw_core/action_list_item.dart";
export "package:cw_core/history_change.dart";
export "package:cw_core/history_filter.dart";

abstract class HistoryEmitter {
  Stream<HistoryChange> get changes;

  bool get hasLoaded;

  HistoryListItem? byId(String id);

  Iterable<HistoryListItem> get items;

  Future<void> dispose();
}

abstract class SnapshotHistoryEmitter extends HistoryEmitter {
  final Map<String, HistoryListItem> _items = {};
  final StreamController<HistoryChange> _changes = StreamController<HistoryChange>.broadcast();

  bool _hasLoaded = false;

  @override
  Stream<HistoryChange> get changes => _changes.stream;

  @override
  bool get hasLoaded => _hasLoaded;

  @override
  HistoryListItem? byId(String id) => _items[id];

  @override
  Iterable<HistoryListItem> get items => _items.values;

  void refresh(Iterable<HistoryListItem> next) {
    final incoming = {for (final item in next) item.id: item};

    for (final id in _items.keys.toList()) {
      if (!incoming.containsKey(id)) {
        _items.remove(id);
        _emit(ItemRemoved(id));
      }
    }

    incoming.forEach((id, item) {
      final existed = _items.containsKey(id);
      _items[id] = item;
      _emit(existed ? ItemUpdated(id) : ItemAdded(id));
    });

    if (!_hasLoaded) {
      _hasLoaded = true;
      _emit(const HistoryLoaded());
    }
  }

  void _emit(HistoryChange change) {
    if (!_changes.isClosed) {
      _changes.add(change);
    }
  }

  @override
  Future<void> dispose() => _changes.close();
}

abstract class HistoryFilters {
  bool relevant(HistoryListItem item);

  List<HistoryFilter> get filters => const [];

  void toggleFilter(HistoryFilter filter) {}

  void setAllFilters({required bool value}) {}

   Iterable<HistoryFilter> get allFilters => filters.expand((filter) => filter.descendants);

}

class HistorySource<EmitterType extends HistoryEmitter, FiltersType extends HistoryFilters> {
  const HistorySource({
    required this.emitter,
    required this.filters,
    this.disposesEmitter = true,
  });

  final EmitterType emitter;
  final FiltersType filters;

  final bool disposesEmitter;

  Iterable<HistoryListItem> get relevantItems => emitter.items.where(filters.relevant);

  Future<void> dispose() async {
    if (disposesEmitter) {
      await emitter.dispose();
    }
  }
}
