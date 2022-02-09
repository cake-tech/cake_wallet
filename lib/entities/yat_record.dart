import 'dart:convert';

import 'package:http/http.dart';

/// Resolves YAT record
class YatRecord {
  String category;
  String address;

  static const yatBaseUrl = "https://a.y.at";

  static String lookupEmojiUrl(String emojiId) =>
      "$yatBaseUrl/emoji_id/$emojiId/payment";

  YatRecord({
    this.category,
    this.address,
  });

  YatRecord.fromJson(Map<String, dynamic> json) {
    address = json['address'] as String;
    category = json['category'] as String;
  }

  static const tags = {
    "XMR": '0x1001,0x1002',
    "BTC": '0x1003',
    "LTC": '0x3fff'
  };

  static Future<List<YatRecord>> fetchYatAddress(
      String emojiId, String ticker) async {
    final formattedTicker = ticker.toUpperCase();
    final formattedEmojiId = emojiId.replaceAll(' ', '');
    final uri = Uri.parse(lookupEmojiUrl(formattedEmojiId)).replace(
        queryParameters: <String, dynamic>{"tags": tags[formattedTicker]});

    final yatRecords = <YatRecord>[];

    try {
      final response = await get(uri);
      final resBody = json.decode(response.body) as Map<String, dynamic>;

      final results = resBody["result"] as Map<dynamic, dynamic>;
      results.forEach((dynamic key, dynamic value) {
        yatRecords.add(YatRecord.fromJson(value as Map<String, dynamic>));
      });

      return yatRecords;
    } catch (_) {
      return yatRecords;
    }
  }
}
