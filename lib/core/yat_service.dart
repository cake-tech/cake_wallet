import 'dart:convert';

import 'package:cake_wallet/entities/yat_record.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';

class YatService {
  static bool isDevMode = false;

  static String get apiUrl =>
      YatService.isDevMode ? YatService.apiDevUrl : YatService.apiReleaseUrl;
  static const apiReleaseUrl = "https://a.y.at";
  static const apiDevUrl = 'https://a.yat.fyi';

  static String lookupEmojiUrl(String emojiId) =>
      "$apiUrl/emoji_id/$emojiId/payment";
  
  static const String MONERO_SUB_ADDRESS = '0x1002';
  static const String MONERO_STD_ADDRESS = '0x1001';
  static const tags = {
    'XMR': "$MONERO_STD_ADDRESS,$MONERO_SUB_ADDRESS",
    'BTC': '0x1003',
    'LTC': '0x1019'
  };

  Future<List<YatRecord>> fetchYatAddress(
      String emojiId,
      String ticker,
      ) async {
    final tagQuery = tags[ticker.toUpperCase()];
    if (tagQuery == null) return const [];

    final uri = Uri.parse(
      lookupEmojiUrl(emojiId.replaceAll(' ', '')),
    ).replace(queryParameters: {'tags': tagQuery});

    try {
      final response = await ProxyWrapper().get(clearnetUri: uri);
      final body = json.decode(response.body) as Map<String, dynamic>;

      final res = body['result'];
      if (res == null) return const [];

      final records = <YatRecord>[];

      if (res is Map) {
        res.forEach((tag, data) {
          if (data is Map<String, dynamic>) {
            records.add(YatRecord.fromJson(data, tag.toString()));
          }
        });
      }

      else if (res is List) {
        for (final item in res) {
          if (item is Map<String, dynamic>) {
            final tag = item['tag']?.toString() ?? '';
            records.add(YatRecord.fromJson(item, tag));
          }
        }
      }

      return records;
    } catch (_) {
      return const [];
    }
  }
}
