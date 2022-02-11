import 'dart:convert';

import 'package:cake_wallet/entities/yat_record.dart';
import 'package:http/http.dart';

class YatService {
  static bool isDevMode = false;

  static String get apiUrl =>
      YatService.isDevMode ? YatService.apiDevUrl : YatService.apiReleaseUrl;
  static const apiReleaseUrl = "https://a.y.at";
  static const apiDevUrl = 'https://yat.fyi';

  static String lookupEmojiUrl(String emojiId) =>
      "$apiUrl/emoji_id/$emojiId/payment";

  Future<List<YatRecord>> fetchYatAddress(String emojiId, String ticker) async {
    final formattedTicker = ticker.toUpperCase();
    final formattedEmojiId = emojiId.replaceAll(' ', '');
    final uri = Uri.parse(lookupEmojiUrl(formattedEmojiId)).replace(
        queryParameters: <String, dynamic>{
          "tags": YatRecord.tags[formattedTicker]
        });

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
