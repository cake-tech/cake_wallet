import 'dart:convert';

import 'package:cake_wallet/cake_pay/src/models/cake_pay_order.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_user_credentials.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_vendor.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cake_wallet/entities/country.dart';

class CakePayApi {
  static const testBaseUri = false;

  static const baseTestCakePayUri = 'test.cakepay.com';
  static const baseProdCakePayUri = 'buy.cakepay.com';

  static const baseCakePayUri = testBaseUri ? baseTestCakePayUri : baseProdCakePayUri;

  static const vendorsPath = '/api/vendors';
  static const countriesPath = '/api/countries';
  static const authPath = '/api/auth';
  static final verifyEmailPath = '/api/verify';
  static final logoutPath = '/api/logout';
  static final createOrderPath = '/api/order';
  static final simulatePaymentPath = '/api/simulate_payment';

  /// AuthenticateUser
  Future<String> authenticateUser({required String email, required String apiKey}) async {
    try {
      final uri = Uri.https(baseCakePayUri, authPath);
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Api-Key $apiKey',
      };
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        headers: headers,
        body: json.encode({'email': email}),
      );

      if (response.statusCode != 200) {
        throw Exception('Unexpected http status: ${response.statusCode}');
      }

      final bodyJson = json.decode(response.body) as Map<String, dynamic>;

      if (bodyJson.containsKey('user') && bodyJson['user']['email'] != null) {
        return bodyJson['user']['email'] as String;
      }

      throw Exception('Failed to authenticate user with error: $bodyJson');
    } catch (e) {
      throw Exception('Failed to authenticate user with error: $e');
    }
  }

  /// Verify email
  Future<CakePayUserCredentials> verifyEmail({
    required String email,
    required String code,
    required String apiKey,
  }) async {
    final uri = Uri.https(baseCakePayUri, verifyEmailPath);
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Api-Key $apiKey',
    };
    final query = <String, String>{'email': email, 'otp': code};

    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: headers,
      body: json.encode(query),
    );

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final bodyJson = json.decode(response.body) as Map<String, dynamic>;

    if (bodyJson.containsKey('error')) {
      throw Exception(bodyJson['error'] as String);
    }

    if (bodyJson.containsKey('token')) {
      final token = bodyJson['token'] as String;
      final userEmail = bodyJson['user']['email'] as String;
      return CakePayUserCredentials(userEmail, token);
    } else {
      throw Exception('E-mail verification failed.');
    }
  }

  /// createOrder
  Future<CakePayOrder> createOrder({
    required String apiKey,
    required int cardId,
    required String price,
    required int quantity,
    required String userEmail,
    required String token,
    required bool confirmsNoVpn,
    required bool confirmsVoidedRefund,
    required bool confirmsTermsAgreed,
  }) async {
    final uri = Uri.https(baseCakePayUri, createOrderPath);

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Api-Key $apiKey',
    };

    final body = json.encode({
      'card_id': cardId,
      'price': price,
      'quantity': quantity,
      'user_email': userEmail,
      'token': token,
      'send_email': true,
      'confirms_no_vpn': confirmsNoVpn,
      'confirms_voided_refund': confirmsVoidedRefund,
      'confirms_terms_agreed': confirmsTermsAgreed,
    });

    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return CakePayOrder.fromMap(data);
    }

    String message = 'Server error ${response.statusCode}';

    final isJson = response.headers['content-type']?.contains('application/json') == true ||
        response.body.trim().startsWith(RegExp(r'[\{\[]'));

    if (isJson) {
      try {
        final decoded = json.decode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          message = decoded.first.toString();
        } else if (decoded is Map && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        } else {
          message = decoded.toString();
        }
      } on FormatException {}
    }

    throw Exception(message);
  }

  ///Simulate Payment
  Future<String> simulatePayment(
      {required String CSRFToken, required String authorization, required String orderId}) async {
    final uri = Uri.https(baseCakePayUri, simulatePaymentPath + '/$orderId');

    final headers = {
      'accept': 'application/json',
      'authorization': authorization,
      'X-CSRFToken': CSRFToken,
    };

    final response = await ProxyWrapper().get(clearnetUri: uri, headers: headers);

    printV('Response: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final bodyJson = json.decode(response.body) as Map<String, dynamic>;

    return 'You just SIMULATED a buying of a gift card with ID: ${bodyJson['order_id']}';
  }

  /// Logout
  Future<void> logoutUser({required String email, required String apiKey}) async {
    final uri = Uri.https(baseCakePayUri, logoutPath);
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Api-Key $apiKey',
    };

    try {
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        headers: headers,
        body: json.encode({'email': email}),
      );

      if (response.statusCode != 200) {
        throw Exception('Unexpected http status: ${response.statusCode}');
      }
    } catch (e) {
      printV('Caught exception: $e');
    }
  }

  /// Get Countries
  Future<List<Country>> getCountries({required String apiKey}) async {
    final uri = Uri.https(baseCakePayUri, countriesPath);

    final headers = {
      'accept': 'application/json',
      'Authorization': 'Api-Key $apiKey',
    };

    final response = await ProxyWrapper().get(clearnetUri: uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final bodyJson = json.decode(response.body) as List;
    return bodyJson
        .map<String>((country) => country['name'] as String)
        .map((name) => Country.fromCakePayName(name))
        .whereType<Country>()
        .toList();
  }

  /// Get Vendors
  Future<List<CakePayVendor>> getVendors({
    required String apiKey,
    required String country,
    int? page,
    String? countryCode,
    String? search,
    List<String>? vendorIds,
    bool? giftCards,
    bool? prepaidCards,
    bool? onDemand,
    bool? custom,
  }) async {
    var queryParams = {
      'page': page?.toString(),
      'country': country,
      'country_code': countryCode,
      'search': search,
      'vendor_ids': vendorIds?.join(','),
      'gift_cards': giftCards?.toString(),
      'prepaid_cards': prepaidCards?.toString(),
      'on_demand': onDemand?.toString(),
      'custom': custom?.toString(),
    };

    final uri = Uri.https(baseCakePayUri, vendorsPath, queryParams);

    var headers = {
      'accept': 'application/json; charset=UTF-8',
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Api-Key $apiKey',
    };

    var response = await ProxyWrapper().get(clearnetUri: uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch vendors: statusCode - ${response.statusCode}, queryParams -$queryParams, response - ${response.body}');
    }

    final bodyJson = json.decode(response.body);

    if (bodyJson is List<dynamic> && bodyJson.isEmpty) {
      return [];
    }

    return (bodyJson['results'] as List)
        .map((e) => CakePayVendor.fromJson(e as Map<String, dynamic>, country))
        .toList();
  }
}
