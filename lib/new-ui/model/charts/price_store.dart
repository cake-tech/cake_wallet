

import 'package:cake_wallet/new-ui/model/charts/price_data.dart';
import 'package:cake_wallet/new-ui/viewmodels/charts/util/chart_range.dart';
import 'package:cw_core/currency.dart';

class PriceStore {
  static Future<List<PriceData>> getPrices(Currency from, Currency to, ChartRange range) async {
    final List<PriceData> ret = [];
    
    final end = DateTime.now();
    final DateTime start;
    if(range.duration == null) {
      start = DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      start = end.subtract(range.duration!);
    }

    final pricesFromDb = await PriceData.get(from, to, start, end);
  }

  static DateTime? firstUnavailablePrice(List<PriceData> prices, Duration precision, DateTime start, DateTime end) {
    final alignedStartMs = (start.millisecondsSinceEpoch / precision.inMilliseconds).floor() * precision.inMilliseconds;
    final alignedStart = DateTime.fromMillisecondsSinceEpoch(alignedStartMs);

    final priceTimestamps = prices.map((p) => p.time.millisecondsSinceEpoch).toSet();

    for (DateTime i = alignedStart; i.isBefore(end); i = i.add(precision)) {
      if (i.isBefore(start)) continue;

      if (!priceTimestamps.contains(i.millisecondsSinceEpoch)) {
        return i;
      }
    }
    return null;
  }
}