import 'dart:convert';
import 'package:cake_wallet/yat/yat_exception.dart';
import 'package:http/http.dart';

Future<String> fetchYatAddress(String emojiId, String ticker) async {
  const _requestURL = 'https://a.y.at/emoji_id/';
  const classValue = '0x10';
  const tagValues = {'xmr' : ['01', '02'], 'btc' : ['03'], 'eth' : ['04']};
  final tagValue = tagValues[ticker];

  if (tagValue == null) {
    return '';
  }

  final url = _requestURL + emojiId;
  final response = await get(url);

  if (response.statusCode != 200) {
    throw YatException(text: response.body.toString());
  }

  final responseJSON = json.decode(response.body) as Map<String, dynamic>;
  final result = responseJSON['result'] as List<dynamic>;

  if (result == null) {
    return '';
  }

  for (var value in tagValue) {
    for (int i = 0; i < result.length; i++) {
      final record = result[i] as Map<String, dynamic>;
      final tag = record['tag'] as String;
      if (tag?.contains(classValue + value) ?? false) {
        final yatAddress = record['data'] as String;
        return yatAddress;
      }
    }
  }

  return '';

  //final yatAddress = responseJSON['result'][2]['data'] as String;
  //return yatAddress;
}