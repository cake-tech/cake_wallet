import 'dart:convert';

import 'package:http/http.dart';

/// Resolves YAT record
class YatRecord {
  String tag;
  String address;

  YatRecord({
    this.tag,
    this.address,
  });

  YatRecord.fromJson(Map<String, dynamic> json) {
    tag = json['tag'] as String;
    address = json['data'] as String;
  }

  static const addressLookupUrl = "https://a.y.at/emoji_id";

  static Future<List<YatRecord>> fetchYatAddress(
      String emojiId, String ticker) async {
    final formattedTicker = ticker.toUpperCase();
    final url = YatRecord.addressLookupUrl + "/$emojiId/$formattedTicker";
    final results = <YatRecord>[];

    try {
      final response = await get(url);
      final resBody = json.decode(response.body) as Map<String, dynamic>;
      if (resBody["error"] == null) if (resBody["result"] != null) {
        for (final result in resBody["result"]) {
          results.add(YatRecord.fromJson(result as Map<String, dynamic>));
        }
      }
      return results;
    } catch (_) {
      return results;
    }
  }
}
