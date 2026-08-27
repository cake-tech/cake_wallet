import "package:cw_core/transaction_info.dart";
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
  final Map<String, String> _sessionIdsByTxId = {};

  late final StreamSubscription<BoxEvent> _subscription;

  PayjoinTransactionListItem? forTransaction(TransactionInfo transaction) {
    final sessionId = _sessionIdsByTxId[transaction.id];
    if (sessionId == null) {
      return null;
    }

    final session = _box.get(sessionId);
    if (session == null) {
      return null;
    }

    return PayjoinTransactionListItem(
      sessionId: sessionId,
      session: session,
      transaction: transaction,
    );
  }

  void _reproject() {
    _sessionIdsByTxId.clear();

    final inFlight = <PayjoinTransactionListItem>[];

    for (final entry in _box.toMap().entries) {
      final session = entry.value;

      if (!_visibleStatuses.contains(session.status) || session.inProgressSince == null) {
        continue;
      }

      final sessionId = entry.key as String;
      final txId = session.txId;

      if (txId == null) {
        inFlight.add(PayjoinTransactionListItem(sessionId: sessionId, session: session));
      } else {
        _sessionIdsByTxId[txId] = sessionId;
      }
    }

    refresh(inFlight);
  }

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
