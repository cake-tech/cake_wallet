import 'dart:convert';
import 'package:cake_wallet/yat/yat_exception.dart';
import 'package:http/http.dart';

Future<String> fetchYatAddress(String emojiId) async {
  const _apiKey = ''; // FIXME
  const _requestURL = 'https://api.y.at/emoji_id/';

  final url = _requestURL + emojiId;

  final response = await get(
      url,
      headers: {
        'Accept': '*/*',
        'Authorization': 'Bearer $_apiKey'
      }
  );

  if (response.statusCode != 200) {
    throw YatException(text: response.body.toString());
  }

  final responseJSON = json.decode(response.body) as Map<String, dynamic>;
  final yatAddress = responseJSON[''] as String; // FIXME
  return yatAddress;
}