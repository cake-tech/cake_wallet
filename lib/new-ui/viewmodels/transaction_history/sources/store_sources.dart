import "dart:async";

import "package:cake_wallet/anonpay/anonpay_invoice_info.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/order/order.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/order_filter_store.dart";
import "package:cake_wallet/store/dashboard/trade_filter_store.dart";
import "package:cake_wallet/store/dashboard/transaction_filter_store.dart";
import "package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart";
import "package:cw_core/history_source.dart";
import "package:cw_core/payjoin_session.dart";
import "package:hive/hive.dart";

/// Trades come from sqlite behind a payload-less signal, so the emitter has to
/// diff to work out what actually changed.
class TradeChangeEmitter extends SnapshotChangeEmitter {
  TradeChangeEmitter() {
    _subscription = Trade.onChanged.stream.listen((_) => _reload());
    _reload();
  }

  late final StreamSubscription<void> _subscription;

  Future<void> _reload() async {
    try {
      refresh(await Trade.getAll());
    } catch (_) {
      // A failed reload still counts as a finished load, so the UI stops waiting.
      refresh(items.toList());
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await super.dispose();
  }
}

/// Hive gives us a box event per change, but its keys are auto-increment
/// integers rather than domain ids, so we reproject and diff by id.
class BoxChangeEmitter<T extends ActionListItem> extends SnapshotChangeEmitter {
  BoxChangeEmitter(this._box) {
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

/// Payjoin needs its box key (the session doesn't carry one) and only shows
/// sessions that have actually started.
class PayjoinChangeEmitter extends SnapshotChangeEmitter {
  PayjoinChangeEmitter(this._box) {
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

class TradeFilters extends HistoryFilters {
  TradeFilters({required this.appStore, required this.filterStore});

  final AppStore appStore;
  final TradeFilterStore filterStore;

  @override
  bool relevant(ActionListItem item) {
    final wallet = appStore.wallet;
    return wallet != null && filterStore.relevant(item, wallet);
  }
}

class OrderFilters extends HistoryFilters {
  OrderFilters({required this.appStore, required this.filterStore});

  final AppStore appStore;
  final OrderFilterStore filterStore;

  @override
  bool relevant(ActionListItem item) {
    final wallet = appStore.wallet;
    return wallet != null && filterStore.relevant(item, wallet);
  }
}

/// Anonpay rows answer to the wallet and to the same date and direction filters
/// as transactions, which is why the transaction filter store handles both.
class AnonpayFilters extends HistoryFilters {
  AnonpayFilters({required this.appStore, required this.filterStore});

  final AppStore appStore;
  final TransactionFilterStore filterStore;

  @override
  bool relevant(ActionListItem item) =>
      item is AnonpayInvoiceInfo &&
      item.walletId == appStore.wallet?.id &&
      filterStore.relevant(item);
}

class PayjoinFilters extends HistoryFilters {
  PayjoinFilters({required this.appStore});

  final AppStore appStore;

  @override
  bool relevant(ActionListItem item) =>
      item is PayjoinTransactionListItem && item.session.walletId == appStore.wallet?.id;
}
