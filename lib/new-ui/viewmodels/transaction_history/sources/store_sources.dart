import "dart:async";

import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart";
import "package:cw_core/history_source.dart";
import "package:cw_core/payjoin_session.dart";
import "package:hive/hive.dart";

class TradeHistoryEmitter extends SnapshotHistoryEmitter {
  TradeHistoryEmitter() {
    _subscription = Trade.onChanged.stream.listen((_) => _reload());
    _reload();
  }

  late final StreamSubscription<void> _subscription;

  Future<void> _reload() async {
    try {
      refresh(await Trade.getAll());
    } catch (_) {
      refresh(items.toList());
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await super.dispose();
  }
}

class BoxHistoryEmitter<T extends HistoryListItem> extends SnapshotHistoryEmitter {
  BoxHistoryEmitter(this._box) {
    _subscription = _box.watch().listen((_) => refresh(_box.values));
    refresh(_box.values);
  }

  final Box<T> _box;
  late final StreamSubscription<BoxEvent> _subscription;

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await super.dispose();
  }
}

class PayjoinHistoryEmitter extends SnapshotHistoryEmitter {
  PayjoinHistoryEmitter(this._box) {
    _subscription = _box.watch().listen((_) => _reproject());
    _reproject();
  }

  static const _visibleStatuses = {"inProgress", "success", "unrecoverable"};

  final Box<PayjoinSession> _box;
  late final StreamSubscription<BoxEvent> _subscription;

  void _reproject() => refresh([
        for (final entry in _box.toMap().entries)
          if (_visibleStatuses.contains(entry.value.status) &&
              entry.value.inProgressSince != null)
            PayjoinTransactionListItem(
              sessionId: entry.key as String,
              session: entry.value,
            ),
      ]);

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await super.dispose();
  }
}

class PayjoinFilterStore extends HistoryFilters {
  PayjoinFilterStore({required this.appStore});

  final AppStore appStore;

  @override
  bool relevant(HistoryListItem item) =>
      item is PayjoinTransactionListItem && item.session.walletId == appStore.wallet?.id;
}
