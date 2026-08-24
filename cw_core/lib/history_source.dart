import "dart:async";

import "package:cw_core/action_list_item.dart";
import "package:cw_core/history_change.dart";

export "package:cw_core/action_list_item.dart";
export "package:cw_core/history_change.dart";

/// Where history rows come from and how they change.
///
/// Ids on [changes] are always [ActionListItem.id] values, never a backing
/// store's own key — translating is the emitter's job, so the consumer works in
/// a single keyspace and can resolve a removal it no longer holds.
abstract class ChangeEmitter {
  Stream<HistoryChange> get changes;

  /// Whether the initial load has finished. Distinct from having no items.
  bool get hasLoaded;

  ActionListItem? byId(String id);

  Iterable<ActionListItem> get items;

  Future<void> dispose();
}

/// A [ChangeEmitter] for sources that can only say "something changed" — a Hive
/// box event, or a payload-less signal. It keeps the last projection and
/// announces the difference, which is what makes removals resolvable.
abstract class SnapshotChangeEmitter extends ChangeEmitter {
  final Map<String, ActionListItem> _items = {};
  final StreamController<HistoryChange> _changes = StreamController<HistoryChange>.broadcast();

  bool _hasLoaded = false;

  @override
  Stream<HistoryChange> get changes => _changes.stream;

  @override
  bool get hasLoaded => _hasLoaded;

  @override
  ActionListItem? byId(String id) => _items[id];

  @override
  Iterable<ActionListItem> get items => _items.values;

  /// Replaces the projection with [next] and emits one change per difference.
  ///
  /// Cheap at these sizes — a few hundred items at most — and it means a source
  /// that can only signal "something changed" still produces a usable journal.
  void refresh(Iterable<ActionListItem> next) {
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
    if (!_changes.isClosed) _changes.add(change);
  }

  @override
  Future<void> dispose() => _changes.close();
}

/// Whether an item belongs in the list right now.
///
/// Called per item, so implementations must be cheap and free of side effects.
/// Everything that narrows the list lives here — current wallet, selected
/// account, user-chosen filters.
abstract class HistoryFilters {
  bool relevant(ActionListItem item);
}

class HistorySource {
  const HistorySource({
    required this.emitter,
    required this.filters,
    this.precedence = 0,
  });

  final ChangeEmitter emitter;
  final HistoryFilters filters;

  /// Higher wins when two sources produce items with the same id — which is how
  /// a payjoin row replaces the plain transaction row for the same txid.
  final int precedence;

  Iterable<ActionListItem> get relevantItems => emitter.items.where(filters.relevant);
}
