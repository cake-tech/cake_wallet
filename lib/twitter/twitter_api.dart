import 'dart:convert';
import 'package:cake_wallet/twitter/twitter_user.dart';
import 'package:http/http.dart' as http;
import 'package:cake_wallet/.secrets.g.dart' as secrets;

class TwitterApi {
  static const twitterBearerToken = secrets.twitterBearerToken;
  static const httpsScheme = 'https';
  static const apiHost = 'api.twitter.com';
  static const userPath = '/2/users/by/username/';

  static Future<TwitterUser> lookupUserByName({required String userName}) async {
    final queryParams = {'user.fields': 'description', 'expansions': 'pinned_tweet_id'};

    final headers = {'authorization': 'Bearer $twitterBearerToken'};

    final uri = Uri(
      scheme: httpsScheme,
      host: apiHost,
      path: userPath + userName,
      queryParameters: queryParams,
    );

    var response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }
    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    if (responseJSON['errors'] != null) {
      throw Exception(responseJSON['errors'][0]['detail']);
    }

    final user = responseJSON['data'] as Map<String, dynamic>;

    try {
      if (responseJSON['includes'] != null) {
        user['pinnedTweet'] = responseJSON['includes']['tweets'][0]['text'];
      }
    } catch (e) {
      print('responseJSON[includes][tweets][0][text] $e');
    }

    return TwitterUser.fromJson(user);
  }
}
