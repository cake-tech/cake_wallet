import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/new-ui/model/charts/datetime_extension.dart';
import 'package:cake_wallet/new-ui/model/charts/price_data.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_zano/zano_wallet_api.dart';

const priceApiHost = "prices.cakewallet.com";

class PriceRequest {
  final DateTime? beginTime;
  final Duration interval;
  final int? count;
  final Currency from;
  final Currency to;

  const PriceRequest(
      {this.beginTime, required this.interval, this.count, required this.from, required this.to});

  Uri get uri => Uri.https(priceApiHost, "/v3/rates", {
        "start": (beginTime?.secondsSinceEpoch ?? 0).toString(),
        "end": DateTime.now().secondsSinceEpoch.toString(),
        "interval": "${interval.inSeconds}",
        if (count != null) "count": count.toString(),
        "quote": from.apiString,
        "base": to.apiString
      });
}

class PriceApiClient {
  static Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    final resp =
        await ProxyWrapper().get(headers: {"x-api-key": secrets.fiatApiKey}, clearnetUri: uri);
    if (!(resp.statusCode >= 200 && resp.statusCode < 300)) {
      printV("server returned code: ${resp.statusCode}\nuri: ${uri}\nresp body: ${resp.body}");
      return null;
    }
    try {
      return jsonDecode(resp.body);
    } catch (e) {
      printV("failed to decode response for ${uri.host}/${uri.path}: $e");
      return null;
    }
  }

  static Future<List<PriceData>> getPrices(PriceRequest request) async {
    final List<PriceData> ret = [];
    final data = (await _getJson(request.uri));
    if (data == null) return [];
    final results = data["results"] as Map<String, dynamic>?;
    if (results == null) {
      printV(data.toString());
      return [];
    }
    for (final time in results.keys) {
      ret.add(PriceData(
          time: DateTimeX.fromSecondsSinceEpoch(int.parse(time)),
          from: request.from,
          to: request.to,
          price: (results[time] as num).toStringAsFixed(2)));
    }
    return ret;
  }
}
