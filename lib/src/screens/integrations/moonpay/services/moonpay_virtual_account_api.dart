import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/asn1.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:crypto/crypto.dart';

class MoonpayVirtualAccountApi {
  static const bool isTestMode = false;

  String get _publishableApiKey => secrets.moonPayApiKey;
  String get _secretKey => secrets.moonPaySecretKey;

  String get _publishableTestApiKey => secrets.moonPayTestApiKey;
  String get _testSecretKey => secrets.moonPayTestSecretKey;

  String get _secretPrivateKey =>
      secrets.moonPayVirtualAccountsPrivateKeyPem;

  String get _currentPublishableApiKey =>
      isTestMode ? _publishableTestApiKey : _publishableApiKey;

  String get _currentSecretKey =>
      isTestMode ? _testSecretKey : _secretKey;

  static const _baseProdUrl = 'https://buy.moonpay.com';
  static const _baseTestUrl = 'https://buy-sandbox.moonpay.com';
  static const _apiBaseUrl = 'https://api.moonpay.com';
  static const _dashboardPath = '/v2/virtual-account';

  String get _baseUrl => isTestMode ? _baseTestUrl : _baseProdUrl;

  /// =========================
  /// CREATE ACCOUNT (HMAC)
  /// =========================
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
      'walletAddressIsPartnerGenerated':
      walletAddressIsPartnerGenerated.toString(),
      'externalCustomerId': externalCustomerId,
    };

    if (email != null) params['email'] = email;
    if (sourceCurrencyCode != null) {
      params['sourceCurrencyCode'] = sourceCurrencyCode;
    }
    if (destinationCurrencyCode != null) {
      params['destinationCurrencyCode'] = destinationCurrencyCode;
    }

    final query = _encodeQuery(params);
    final signature = _signHmac('?$query');

    return '$_baseUrl$_dashboardPath?$query&signature=${Uri.encodeQueryComponent(signature)}';
  }

  /// =========================
  /// ACCOUNT ACCESS (NO SIGN)
  /// =========================
  String buildAccountAccessUrl({String? theme}) {
    final params = <String, String>{
      'apiKey': _currentPublishableApiKey,
    };

    if (theme != null) params['theme'] = theme;

    final query = _encodeQuery(params);
    return '$_baseUrl$_dashboardPath?$query';
  }

  /// =========================
  /// FETCH ACCOUNT DETAILS (RSA)
  /// =========================
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

    print('fetchVirtualAccountDetails response::::::::; $responseBody');

    final decoded = json.decode(responseBody);

    if (decoded is List) return decoded;
    if (decoded is Map && decoded['data'] is List) {
      return (decoded['data'] as List).cast<dynamic>();
    }

    throw Exception('Unexpected response');
  }

  /// =========================
  /// FETCH TRANSACTIONS (RSA)
  /// =========================
  Future<Map<String, dynamic>> fetchOnRampTransactions({
    String? externalCustomerId,
    String? virtualAccountId,
    int pageSize = 50,
    String? cursor,
  }) async {
    if ((externalCustomerId == null || externalCustomerId.isEmpty) &&
        (virtualAccountId == null || virtualAccountId.isEmpty)) {
      throw ArgumentError('Provide id');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    final params = <String, String>{
      'apiKey': _currentPublishableApiKey,
      'timestamp': timestamp,
      'pageSize': pageSize.toString(),
    };

    if (externalCustomerId != null) {
      params['externalCustomerId'] = externalCustomerId;
    }
    if (virtualAccountId != null) {
      params['virtualAccountId'] = virtualAccountId;
    }
    if (cursor != null) params['cursor'] = cursor;

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

    throw Exception('Unexpected response');
  }

  /// =========================
  /// RSA SIGN (PKCS#1)
  /// =========================
  String _signRsaSha256(String payload) {
    var pem = _secretPrivateKey.trim();
    pem = pem.replaceAll(r'\n', '\n');

    final privateKey = _parsePkcs1PrivateKeyFromPem(pem);

    final signer = Signer('SHA-256/RSA');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final sig = signer.generateSignature(
      Uint8List.fromList(utf8.encode(payload)),
    ) as RSASignature;

    return base64.encode(sig.bytes);
  }

  RSAPrivateKey _parsePkcs1PrivateKeyFromPem(String pem) {
    final derBytes = _decodePem(pem);
    final parser = ASN1Parser(derBytes);
    final seq = parser.nextObject() as ASN1Sequence;

    final modulus = (seq.elements![1] as ASN1Integer).integer!;
    final privateExponent = (seq.elements![3] as ASN1Integer).integer!;
    final p = (seq.elements![4] as ASN1Integer).integer!;
    final q = (seq.elements![5] as ASN1Integer).integer!;

    return RSAPrivateKey(modulus, privateExponent, p, q);
  }

  Uint8List _decodePem(String pem) {
    final lines = pem
        .split('\n')
        .where((l) =>
    !l.startsWith('-----BEGIN') &&
        !l.startsWith('-----END') &&
        l.trim().isNotEmpty)
        .toList();

    return Uint8List.fromList(base64.decode(lines.join()));
  }

  /// =========================
  /// HTTP
  /// =========================
  Future<String> _httpGet(Uri uri,
      {Map<String, String>? headers}) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers?.forEach((k, v) => request.headers.set(k, v));

      final response = await request.close();
      print('_httpGet response status: >>>>>>>>>>>.${response.statusCode}');
      final body = await response.transform(utf8.decoder).join();

      print('_httpGet response body: :::::::::::::;$body');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}: $body');
      }

      return body;
    } finally {
      client.close(force: true);
    }
  }

  /// =========================
  /// UTILS
  /// =========================
  String _encodeQuery(Map<String, String> params) {
    final entries = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries
        .map((e) =>
    '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }

  String _signHmac(String query) {
    final key = utf8.encode(_currentSecretKey);
    final bytes = utf8.encode(query);
    final digest = Hmac(sha256, key).convert(bytes);
    return base64.encode(digest.bytes);
  }
}