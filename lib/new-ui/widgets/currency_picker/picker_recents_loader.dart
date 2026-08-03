import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart';
import 'package:cake_wallet/order/order.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:hive/hive.dart';

class PickerRecentsLoader {
  const PickerRecentsLoader._();

  static const int defaultLimit = 6;

  static final Set<TradeState> _executedTradeStates = {
    TradeState.complete,
    TradeState.completed,
    TradeState.finished,
    TradeState.success,
    TradeState.settled,
    TradeState.traded,
  };

  static Future<List<CryptoCurrency>> load({
    required RecentsSource source,
    required List<CryptoCurrency> visibleItems,
    int limit = defaultLimit,
  }) async {
    switch (source) {
      case RecentsSource.none:
        return const [];
      case RecentsSource.trades:
        return _fromTrades(visibleItems, limit);
      case RecentsSource.orders:
        return _fromOrders(visibleItems, limit);
    }
  }

  static Future<List<CryptoCurrency>> _fromTrades(
    List<CryptoCurrency> visibleItems,
    int limit,
  ) async {
    final trades = await Trade.getAll();
    final ordered = trades.where((t) => _executedTradeStates.contains(t.state)).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

    return _collect(
      ordered.expand((t) => [t.from, t.to]),
      visibleItems,
      limit,
    );
  }

  static Future<List<CryptoCurrency>> _fromOrders(
    List<CryptoCurrency> visibleItems,
    int limit,
  ) async {
    final orders = Hive.box<Order>(Order.boxName).values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _collect(
      orders.expand((o) => [_tryResolve(o.from), _tryResolve(o.to)]),
      visibleItems,
      limit,
    );
  }

  static List<CryptoCurrency> _collect(
    Iterable<CryptoCurrency?> candidates,
    List<CryptoCurrency> visibleItems,
    int limit,
  ) {
    final visibleSet = visibleItems.toSet();
    final seen = <CryptoCurrency>{};
    final collected = <CryptoCurrency>[];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      if (!visibleSet.contains(candidate)) continue;
      if (!seen.add(candidate)) continue;
      collected.add(candidate);
      if (collected.length >= limit) break;
    }

    return collected;
  }

  static CryptoCurrency? _tryResolve(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return CryptoCurrency.fromString(raw);
    } catch (_) {
      return null;
    }
  }
}
