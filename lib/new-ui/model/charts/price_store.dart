import "package:cake_wallet/new-ui/model/charts/price_api_client.dart";
import "package:cake_wallet/new-ui/model/charts/price_data.dart";
import "package:cake_wallet/new-ui/model/charts/util/chart_range.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/utils/print_verbose.dart";

abstract class PriceSource {
  const PriceSource();

  Future<List<PriceData>> get(
    DateTime start,
    DateTime end,
    Currency from,
    Currency to,
    Duration interval,
  );
}

mixin UpdatablePriceSource {
  Future<void> update(Iterable<PriceData> newData);
}

class DatabasePriceSource extends PriceSource with UpdatablePriceSource {
  const DatabasePriceSource();

  @override
  Future<List<PriceData>> get(
    DateTime start,
    DateTime end,
    Currency from,
    Currency to,
    Duration interval,
  ) =>
      PriceData.get(from, to, start, end);

  @override
  Future<void> update(Iterable<PriceData> newData) async {
    await PriceData.insertMany(newData);
  }
}

class ApiPriceSource extends PriceSource {
  const ApiPriceSource();

  @override
  Future<List<PriceData>> get(
    DateTime start,
    DateTime end,
    Currency from,
    Currency to,
    Duration interval,
  ) =>
      PriceApiClient.getPrices(
        PriceRequest(beginTime: start, interval: interval, from: from, to: to),
      );
}

class PriceStore {
  static const priceSources = [
    // TODO InMemoryPriceSource() - easily implementable w this pattern but idk if we need to optimize this that much
    DatabasePriceSource(),
    ApiPriceSource(),
  ];

  Future<List<PriceData>> getPrices(Currency from, Currency to, ChartRange range) async {
    final Set<PriceData> data = {};

    final end = DateTime.now();
    DateTime? start;
    if (range.duration == null) {
      start = DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      start = end.subtract(range.duration!);
    }
    start = _alignedStart(start, range.dataPrecision);
    final alignedStart = start;

    for (final source in priceSources) {
      final sourceData = await source.get(start!, end, from, to, range.dataPrecision);
      data.addAll(sourceData);
      start = _firstUnavailablePrice(data.toList(), range.dataPrecision, start, end);
      if (start == null) {
        break;
      }
    }

    for (final source in priceSources) {
      if (source case final UpdatablePriceSource s) {
        await s.update(data);
      }
    }

    return _alignedData(alignedStart, end, data, range.dataPrecision);
  }

  static List<PriceData> _alignedData(
    DateTime start,
    DateTime end,
    Iterable<PriceData> data,
    Duration precision,
  ) {
    final ret = data
        .where((datum) => datum.time.millisecondsSinceEpoch % precision.inMilliseconds == 0)
        .toList();
    ret.sort((a, b) => a.time.compareTo(b.time));
    return ret;
  }

  static DateTime _alignedStart(DateTime start, Duration precision) {
    final alignedStartMs =
        (start.millisecondsSinceEpoch ~/ precision.inMilliseconds) * precision.inMilliseconds;
    return DateTime.fromMillisecondsSinceEpoch(alignedStartMs);
  }

  static DateTime? _firstUnavailablePrice(
    List<PriceData> prices,
    Duration precision,
    DateTime start,
    DateTime end,
  ) {
    if (prices.isEmpty) {
      return start;
    }
    prices.sort();
    final last = prices.last;
    printV("last.time: ${last.time.toIso8601String()} end: ${end.toIso8601String()}");
    if (last.time.isAfter(end.subtract(precision)) ||
        last.time.isAtSameMomentAs(end.subtract(precision))) {
      return null;
    }
    return last.time.add(precision);
  }
}
