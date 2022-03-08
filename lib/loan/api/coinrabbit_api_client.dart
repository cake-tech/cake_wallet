import 'dart:convert';

import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/loan/models/captcha_response.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Thrown if an exception occurs while making an `http` request.
class HttpException implements Exception {}

/// Thrown if an `http` request returns a non-200 status code.
class HttpRequestFailure implements Exception {
  const HttpRequestFailure(this.statusCode);

  /// The status code of the response.
  final int statusCode;
}

/// Thrown when an error occurs while decoding the response body.
class JsonDecodeException implements Exception {}

/// Thrown when an error occurs while deserializing the response body.
class JsonDeserializationException implements Exception {}

/// A Dart API Client for the CoinRabbit REST API.
class CoinRabbitApiClient {
  CoinRabbitApiClient(
      {http.Client httpClient, SharedPreferences sharedPreferences})
      : _httpClient = httpClient ?? http.Client(),
        _sharedPreferences = sharedPreferences;

  /// The host URL used for all API requests.
  static const authority = 'https://api-staging.coinrabbit.io';

  final http.Client _httpClient;

  final SharedPreferences _sharedPreferences;

  static const monitorList = 'MONITOR_LIST';
  static const confirmLoanCreate = 'CONFIRM_LOAN_CREATE';
  static const confirmLoanRepayment = 'CONFIRM_LOAN_REPAYMENT';
  static const confirmEarnCreate = 'CONFIRM_EARN_CREATE';
  static const confirmEarnWithdraw = 'CONFIRM_EARN_WITHDRAW';
  static const secondCredential = 'SECOND_CREDENTIAL';

  /// Get Captcha Challange for authentication.
  ///
  /// REST call: `GET /v2/utils/captcha`
  Future<CaptchaResponse> getCaptchaChallenge() async {
    final uri = Uri.https(authority, '/v2/utils/captcha');
    final responseBody = await _get(uri) as Map<String, dynamic>;

    try {
      return CaptchaResponse.fromJson(responseBody);
    } catch (_) {
      throw JsonDeserializationException();
    }
  }

  /// Send verification code for authentication.
  /// Returns a token String
  ///
  /// REST call: `POST /v2/utils/verification-code/send`
  Future<String> sendVerificationCode(String channel, bool isEmail) async {
    final uri = Uri.https(authority, '/v2/utils/verification-code/send');
    final captcha = await getCaptchaChallenge();

    final body = {
      'type': monitorList,
      'geetest_challenge': captcha.challenge,
      'geetest_seccode': captcha.gt,
      'geetest_validate': captcha.gt
    };
    if (isEmail) {
      body.addAll({"email": channel});
    } else {
      body.addAll({"phone": channel});
    }

    final responseBody =
        await _post(uri: uri, body: body) as Map<String, dynamic>;

    try {
      final isActive2fa = responseBody['is_active_2fa'] as bool;
      await _sharedPreferences.setBool(PreferencesKey.isActive2fa, isActive2fa);

      return responseBody['tokens'][0] as String;
    } catch (_) {
      throw JsonDeserializationException();
    }
  }

  /// Verify the verification code for authentication.
  /// Returns a token String
  ///
  /// REST call: `POST /v2/utils/verification-code/verify`
  Future<String> verifyCode(String code, String verificationToken) async {
    final uri = Uri.https(authority, '/v2/utils/verification-code/verify');
    final headers = {
      'x-api-key': '04b6e4b9-ba09-4d0b-9b6f-13a0bc7cb348',
      'Content-Type': 'application/json'
    };
    final body = {'verification_token': verificationToken, 'code': code};

    final responseBody = await _post(uri: uri, body: body, headers: headers)
        as Map<String, dynamic>;

    try {
      return responseBody['token'] as String;
    } catch (_) {
      throw JsonDeserializationException();
    }
  }

  /// Validates crypto address network.
  /// Returns a token String
  ///
  /// REST call: `POST /v2/utils/validate-address`
  Future<bool> validateAddressByNetwork(
      {String address, String network}) async {
    final uri = Uri.https(authority, '/v2/utils/validate-address');
    final headers = {
      'x-api-key': '04b6e4b9-ba09-4d0b-9b6f-13a0bc7cb348',
      'Content-Type': 'application/json'
    };
    final body = {'address': address, 'network': network};

    final responseBody = await _httpClient.post(uri,
        body: body, headers: headers) as Map<String, dynamic>;

    try {
      return responseBody['message'] as String == 'OK';
    } catch (_) {
      throw HttpException();
    }
  }

  Future<dynamic> _get(Uri uri) async {
    http.Response response;

    try {
      response = await _httpClient.get(uri);
    } catch (_) {
      throw HttpException();
    }

    if (response.statusCode != 200) {
      throw HttpRequestFailure(response.statusCode);
    }

    try {
      final res = json.decode(response.body) as Map<String, Object>;
      return res['response'];
    } catch (e) {
      throw JsonDecodeException();
    }
  }

  Future<dynamic> _post(
      {Uri uri, dynamic body, Map<String, String> headers}) async {
    http.Response response;

    try {
      response = await _httpClient.post(uri, body: body, headers: headers);
    } catch (_) {
      throw HttpException();
    }

    if (response.statusCode != 200) {
      throw HttpRequestFailure(response.statusCode);
    }

    try {
      final res = json.decode(response.body) as Map<String, Object>;
      return res['response'];
    } catch (e) {
      throw JsonDecodeException();
    }
  }
}
