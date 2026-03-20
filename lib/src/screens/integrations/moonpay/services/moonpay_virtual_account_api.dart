import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:crypto/crypto.dart';

class MoonpayVirtualAccountApi {
  MoonpayVirtualAccountApi({String? virtualAccountsPrivateKeyPem})
      : _virtualAccountsPrivateKeyPem = virtualAccountsPrivateKeyPem;

  final String? _virtualAccountsPrivateKeyPem;

  static const bool isTestMode = false;

  String get _publishableApiKey => secrets.moonPayApiKey;

  String get _secretKey => secrets.moonPaySecretKey;

  String get _publishableTestApiKey => secrets.moonPayTestApiKey;

  String get _testSecretKey => secrets.moonPayTestSecretKey;

  String get _currentPublishableApiKey => isTestMode ? _publishableTestApiKey : _publishableApiKey;

  String get _currentSecretKey => isTestMode ? _testSecretKey : _secretKey;

  static const _baseProdUrl = 'https://buy.moonpay.com';
  static const _baseTestUrl = 'https://buy-sandbox.moonpay.com';
  static const _apiBaseUrl = 'https://api.moonpay.com';
  static const _dashboardPath = '/v2/virtual-account';

  String get _baseUrl => isTestMode ? _baseTestUrl : _baseProdUrl;

  /// Onboarding / Create Virtual Account entrypoint (SIGNED).
  String buildCreateAccountUrl({
    required String walletAddress,
    required bool walletAddressIsPartnerGenerated,
    required String externalCustomerId,
    String? theme,
    String? email,
    String? sourceCurrencyCode,
    String? destinationCurrencyCode,
  }) {
    final params = <String, String>{
      'apiKey': _currentPublishableApiKey,
      'theme': theme ?? 'dark',
      'walletAddress': walletAddress,
      'walletAddressIsPartnerGenerated': walletAddressIsPartnerGenerated.toString(),
      'externalCustomerId': externalCustomerId,
    };

    if (email != null) {
      params['email'] = email;
    }

    if (sourceCurrencyCode != null) {
      params['sourceCurrencyCode'] = sourceCurrencyCode;
    }

    if (destinationCurrencyCode != null) {
      params['destinationCurrencyCode'] = destinationCurrencyCode;
    }

    final query = _encodeQuery(params);
    final signature = _sign('?$query');

    return '$_baseUrl$_dashboardPath?$query&signature=${Uri.encodeQueryComponent(signature)}';
  }

  /// Account access / Top up & history entrypoint.
  String buildAccountAccessUrl({String? theme}) {
    final params = <String, String>{
      'apiKey': _currentPublishableApiKey,
    };

    if (theme != null) {
      params['theme'] = theme;
    }

    final query = _encodeQuery(params);
    return '$_baseUrl$_dashboardPath?$query';
  }

  /// Fetch Virtual Account details via MoonPay Virtual Accounts API.
  Future<List<dynamic>> fetchVirtualAccountDetails({
    String? externalCustomerId,
    String? virtualAccountId,
    String? walletAddress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    final params = <String, String>{
      'apiKey': _currentPublishableApiKey,
      'timestamp': timestamp,
    };

    if (externalCustomerId != null && externalCustomerId.isNotEmpty) {
      params['externalCustomerId'] = externalCustomerId;
    }

    if (virtualAccountId != null && virtualAccountId.isNotEmpty) {
      params['virtualAccountId'] = virtualAccountId;
    }

    if (walletAddress != null && walletAddress.isNotEmpty) {
      params['walletAddress'] = walletAddress;
    }

    final query = _encodeQuery(params);
    const path = '/v1/virtual-accounts';
    final payload = '$path?$query';

    final signature = _signRsaSha256(payload);

    final uri = Uri.parse('$_apiBaseUrl$payload');
    final responseBody = await _httpGet(uri, headers: {
      'x-signature': signature,
      'Content-Type': 'application/json',
    });

    print('fetchVirtualAccountDetails raw response: $responseBody');

    final decoded = json.decode(responseBody);

    print('fetchVirtualAccountDetails response: $decoded');
    if (decoded is List) return decoded;

    // Some environments may wrap the response.
    if (decoded is Map && decoded['data'] is List) {
      return (decoded['data'] as List).cast<dynamic>();
    }

    throw Exception('Unexpected Virtual Accounts details response shape');
  }

  /// Fetch Virtual Account OnRamp transactions via MoonPay Virtual Accounts API.
  Future<Map<String, dynamic>> fetchOnRampTransactions({
    String? externalCustomerId,
    String? virtualAccountId,
    int pageSize = 50,
    String? cursor,
  }) async {
    if ((externalCustomerId == null || externalCustomerId.isEmpty) &&
        (virtualAccountId == null || virtualAccountId.isEmpty)) {
      throw ArgumentError('Provide either externalCustomerId or virtualAccountId');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    final params = <String, String>{
      'apiKey': _currentPublishableApiKey,
      'timestamp': timestamp,
      'pageSize': pageSize.toString(),
    };

    if (externalCustomerId != null && externalCustomerId.isNotEmpty) {
      params['externalCustomerId'] = externalCustomerId;
    }

    if (virtualAccountId != null && virtualAccountId.isNotEmpty) {
      params['virtualAccountId'] = virtualAccountId;
    }

    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }

    final query = _encodeQuery(params);
    const path = '/v1/virtual-accounts/transactions/onramp';
    final payload = '$path?$query';

    final signature = _signRsaSha256(payload);

    final uri = Uri.parse('$_apiBaseUrl$payload');
    final responseBody = await _httpGet(uri, headers: {
      'x-signature': signature,
      'Content-Type': 'application/json',
    });

    final decoded = json.decode(responseBody);
    if (decoded is Map<String, dynamic>) return decoded;

    throw Exception('Unexpected Virtual Accounts transactions response shape');
  }

  String _signRsaSha256(String payload) {
    final pem = _virtualAccountsPrivateKeyPem;
    if (pem == null || pem.trim().isEmpty) {
      throw StateError(
        'Virtual Accounts private key PEM is missing. Pass it via MoonpayVirtualAccountApi(virtualAccountsPrivateKeyPem: ...) ',
      );
    }

    final privateKey = CryptoUtils.rsaPrivateKeyFromPem(pem);

    final signer = Signer('SHA-256/RSA');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final sig = signer.generateSignature(Uint8List.fromList(utf8.encode(payload))) as RSASignature;
    return base64.encode(sig.bytes);
  }

  Future<String> _httpGet(Uri uri, {Map<String, String>? headers}) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers?.forEach((k, v) => request.headers.set(k, v));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}: $body', uri: uri);
      }

      return body;
    } finally {
      client.close(force: true);
    }
  }

  String _encodeQuery(Map<String, String> params) {
    final entries = params.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }

  String _sign(String queryWithQuestionMark) {
    final key = utf8.encode(_currentSecretKey);
    final bytes = utf8.encode(queryWithQuestionMark);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return base64.encode(digest.bytes);
  }
}
