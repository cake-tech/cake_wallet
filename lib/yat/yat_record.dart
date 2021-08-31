import 'dart:convert';
import 'package:cake_wallet/yat/yat_exception.dart';
import 'package:http/http.dart';

Future<String> fetchYatAddress(String emojiId, String ticker) async {
  const _requestURL = 'https://a.y.at/emoji_id/';

  final url = _requestURL + emojiId + '/' + ticker.toUpperCase();
  final response = await get(url);

  if (response.statusCode != 200) {
    throw YatException(text: response.body.toString());
  }

  final responseJSON = json.decode(response.body) as Map<String, dynamic>;
  final result = responseJSON['result'] as List<dynamic>;

  if (result == null || result.isEmpty) {
    return '';
  }

  final yatAddress = result.first['data'] as String;
  return yatAddress;
}