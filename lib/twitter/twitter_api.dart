import 'dart:convert';
import 'package:cake_wallet/twitter/twitter_user.dart';
import 'package:http/http.dart' as http;
import 'package:cake_wallet/.secrets.g.dart' as secrets;

class TwitterApi {
  static const twitterBearerToken = 'AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA';
  static const httpsScheme = 'https';
  static const apiHost = 'api.twitter.com';
  static const userPath = '/graphql/hVhfo_TquFTmgL7gYwf91Q/UserByScreenName';
  static const apiGUEST = '/1.1/guest/activate.json';

  static Future<TwitterUser> lookupUserByName({required String userName}) async {
    final queryParams = {'queryId': 'hVhfo_TquFTmgL7gYwf91Q', 'variables': '{"screen_name": "$userName", "withSafetyModeUserFields": true, "withSuperFollowsUserFields": true}', 'features': '{"responsive_web_twitter_blue_verified_badge_is_enabled": true, "verified_phone_label_enabled": false, "responsive_web_graphql_timeline_navigation_enabled": true}'};

    final headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36', 'authorization': 'Bearer $twitterBearerToken'};

    final uri = Uri(
      scheme: httpsScheme,
      host: apiHost,
      path: apiGUEST,
    );

    var response = await http.post(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }
    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    if (responseJSON['errors'] != null) {
      throw Exception(responseJSON['errors'][0]['detail']);
    }

    final guest_token = responseJSON['guest_token'];
    headers.addAll({
    "Content-type": "application/json",
    "x-guest-token": guest_token,
    "x-twitter-active-user": "yes",
    "x-twitter-client-language": "en"});

    final uri2 = Uri(
      scheme: httpsScheme,
      host: apiHost,
      path: apiUSER,
      queryParameters: queryParams);
    
    var response2 = await http.get(uri2, headers: headers);
    if (response2.statusCode != 200) {
      throw Exception('Unexpected http status: ${response2.statusCode}');
    }
    final response2JSON = json.decode(response2.body) as Map<String, dynamic>;
    

    return TwitterUser.fromJson(response2JSON);
  }
}
