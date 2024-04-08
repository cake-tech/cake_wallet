import 'dart:convert';

import 'package:cake_wallet/ionia/cake_pay_card.dart';
import 'package:cake_wallet/ionia/cake_pay_vendor.dart';
import 'package:cake_wallet/ionia/ionia_category.dart';
import 'package:cake_wallet/ionia/ionia_order.dart';
import 'package:cake_wallet/ionia/cake_pay_user_credentials.dart';
import 'package:cake_wallet/ionia/ionia_virtual_card.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

class CakePayApi {
  static const testBaseUri = true;

  static const authorization = 'Basic Y2FrZXdhbGxldDo1ZyIvKnp7K2EwZnZ7KkU6fC0nIg==';
  static const CSRFToken = 'h1EHoAb0riS5lA5BBYDI7REKdBCXJQNuXzZtB0Zx1hh1Q0HG4ztzFGXHrd6kYHfr';

  static const baseTestCakePayUri = 'test.cakepay.com';
  static const baseProdCakePayUri = 'buy.cakepay.com';

  static const baseCakePayUri = testBaseUri ? baseTestCakePayUri : baseProdCakePayUri;

  static const vendorsPath = '/api/vendors';
  static const countriesPath = '/api/countries';
  static const authPath = '/api/auth';
  static final verifyEmailPath = '/api/verify';
  static final logoutPath = '/api/logout';

  static const baseUri = 'api.ionia.io';
  static const pathPrefix = 'cake';
  static const requestedUUIDHeader = 'requestedUUID';

  static final createCardUri = Uri.https(baseUri, '/$pathPrefix/CreateCard');
  static final getMerchantsByFilterUrl = Uri.https(baseUri, '/$pathPrefix/GetMerchantsByFilter');
  static final getPurchaseMerchantsUrl = Uri.https(baseUri, '/$pathPrefix/PurchaseGiftCard');
  static final getCurrentUserGiftCardSummariesUrl =
      Uri.https(baseUri, '/$pathPrefix/GetCurrentUserGiftCardSummaries');
  static final changeGiftCardUrl = Uri.https(baseUri, '/$pathPrefix/ChargeGiftCard');
  static final getGiftCardUrl = Uri.https(baseUri, '/$pathPrefix/GetGiftCard');
  static final getPaymentStatusUrl = Uri.https(baseUri, '/$pathPrefix/PaymentStatus');

  /// AuthenticateUser
  Future<String> authenticateUser({required String email, required String apiKey}) async {
    try {
      final uri = Uri.https(baseCakePayUri, authPath);
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Api-Key $apiKey',
      };
      final response = await http.post(uri, headers: headers, body: json.encode({'email': email}));

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

    final response = await http.post(uri, headers: headers, body: json.encode(query));

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

  /// Logout
  Future<void> logoutUser({required String email, required String apiKey}) async {
    final uri = Uri.https(baseCakePayUri, logoutPath);
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Api-Key $apiKey',
    };

    try {
      final response = await http.post(uri, headers: headers, body: json.encode({'email': email}));

      if (response.statusCode != 200) {
        throw Exception('Unexpected http status: ${response.statusCode}');
      }
    } catch (e) {
      print('Caught exception: $e');
    }
  }

  // Create virtual card

  Future<CakePayVirtualCard> createCard(
      {required String username, required String password, required String clientId}) async {
    final headers = <String, String>{
      'clientId': clientId,
      'username': username,
      'password': password
    };
    final response = await post(createCardUri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final bodyJson = json.decode(response.body) as Map<String, dynamic>;
    final data = bodyJson['Data'] as Map<String, dynamic>;
    final isSuccessful = bodyJson['Successful'] as bool? ?? false;

    if (!isSuccessful) {
      throw Exception(data['message'] as String);
    }

    return CakePayVirtualCard.fromMap(data);
  }

  Future<List<String>> getCountries() async {
    final uri = Uri.https(baseCakePayUri, countriesPath);

    final headers = {
      'accept': 'application/json',
      'authorization': authorization,
      'X-CSRFToken': CSRFToken,
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final bodyJson = json.decode(response.body) as List;

    return bodyJson.map<String>((country) => country['name'] as String).toList();
  }

  Future<List<CakePayVendor>> getVendors({
    int? page,
    String? country,
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
      'authorization': authorization,
      'X-CSRFToken': CSRFToken,
    };

    var response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }
    final bodyJson = json.decode(response.body) as Map<String, dynamic>;

    return (bodyJson['results'] as List)
        .map((e) => CakePayVendor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Get Merchants By Filter

  Future<List<IoniaMerchant>> getMerchantsByFilter(
      {String? search, List<IoniaCategory>? categories, int merchantFilterType = 0}) async {
    // MerchantFilterType: {All = 0, Nearby = 1, Popular = 2, Online = 3, MyFaves = 4, Search = 5}

    final headers = <String, String>{'Content-Type': 'application/json'};
    final body = <String, dynamic>{'MerchantFilterType': merchantFilterType};

    if (search != null) {
      body['SearchCriteria'] = search;
    }

    if (categories != null) {
      body['Categories'] = categories.map((e) => e.ids).expand((e) => e).toList();
    }

    final response = await post(getMerchantsByFilterUrl, headers: headers, body: json.encode(body));

    if (response.statusCode != 200) {
      return [];
    }

    final decodedBody = json.decode(response.body) as Map<String, dynamic>;
    final isSuccessful = decodedBody['Successful'] as bool? ?? false;

    if (!isSuccessful) {
      return [];
    }

    final data = decodedBody['Data'] as List<dynamic>;
    final merch = <IoniaMerchant>[];

    for (final item in data) {
      try {
        final element = item['Merchant'] as Map<String, dynamic>;
        merch.add(IoniaMerchant.fromJsonMap(element));
      } catch (_) {}
    }

    return merch;
  }

  // Purchase Gift Card

  Future<IoniaOrder> purchaseGiftCard(
      {required String requestedUUID,
      required String merchId,
      required double amount,
      required String currency,
      required String username,
      required String password,
      required String clientId}) async {
    final headers = <String, String>{
      'clientId': clientId,
      'username': username,
      'password': password,
      requestedUUIDHeader: requestedUUID,
      'Content-Type': 'application/json'
    };
    final body = <String, dynamic>{'Amount': amount, 'Currency': currency, 'MerchantId': merchId};
    final response = await post(getPurchaseMerchantsUrl, headers: headers, body: json.encode(body));

    if (response.statusCode != 200) {
      throw Exception('Unexpected response');
    }

    final decodedBody = json.decode(response.body) as Map<String, dynamic>;
    final isSuccessful = decodedBody['Successful'] as bool? ?? false;

    if (!isSuccessful) {
      throw Exception(decodedBody['ErrorMessage'] as String);
    }

    final data = decodedBody['Data'] as Map<String, dynamic>;
    return IoniaOrder.fromMap(data);
  }

  // Get Current User Gift Card Summaries

  Future<List<IoniaGiftCard>> getCurrentUserGiftCardSummaries(
      {required String username, required String password, required String clientId}) async {
    final headers = <String, String>{
      'clientId': clientId,
      'username': username,
      'password': password
    };
    final response = await post(getCurrentUserGiftCardSummariesUrl, headers: headers);

    if (response.statusCode != 200) {
      return [];
    }

    final decodedBody = json.decode(response.body) as Map<String, dynamic>;
    final isSuccessful = decodedBody['Successful'] as bool? ?? false;

    if (!isSuccessful) {
      return [];
    }

    final data = decodedBody['Data'] as List<dynamic>;
    final cards = <IoniaGiftCard>[];

    for (final item in data) {
      try {
        final element = item as Map<String, dynamic>;
        cards.add(IoniaGiftCard.fromJsonMap(element));
      } catch (_) {}
    }

    return cards;
  }

  // Charge Gift Card

  Future<void> chargeGiftCard(
      {required String username,
      required String password,
      required String clientId,
      required int giftCardId,
      required double amount}) async {
    final headers = <String, String>{
      'clientId': clientId,
      'username': username,
      'password': password,
      'Content-Type': 'application/json'
    };
    final body = <String, dynamic>{'Id': giftCardId, 'Amount': amount};
    final response = await post(changeGiftCardUrl, headers: headers, body: json.encode(body));

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update Gift Card with ID ${giftCardId};Incorrect response status: ${response.statusCode};');
    }

    final decodedBody = json.decode(response.body) as Map<String, dynamic>;
    final isSuccessful = decodedBody['Successful'] as bool? ?? false;

    if (!isSuccessful) {
      final data = decodedBody['Data'] as Map<String, dynamic>;
      final msg = data['Message'] as String? ?? '';

      if (msg.isNotEmpty) {
        throw Exception(msg);
      }

      throw Exception('Failed to update Gift Card with ID ${giftCardId};');
    }
  }

  // Get Gift Card

  Future<IoniaGiftCard> getGiftCard(
      {required String username,
      required String password,
      required String clientId,
      required int id}) async {
    final headers = <String, String>{
      'clientId': clientId,
      'username': username,
      'password': password,
      'Content-Type': 'application/json'
    };
    final body = <String, dynamic>{'Id': id};
    final response = await post(getGiftCardUrl, headers: headers, body: json.encode(body));

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to get Gift Card with ID ${id};Incorrect response status: ${response.statusCode};');
    }

    final decodedBody = json.decode(response.body) as Map<String, dynamic>;
    final isSuccessful = decodedBody['Successful'] as bool? ?? false;

    if (!isSuccessful) {
      final msg = decodedBody['ErrorMessage'] as String ?? '';

      if (msg.isNotEmpty) {
        throw Exception(msg);
      }

      throw Exception('Failed to get Gift Card with ID ${id};');
    }

    final data = decodedBody['Data'] as Map<String, dynamic>;
    return IoniaGiftCard.fromJsonMap(data);
  }

  // Payment Status

  Future<int> getPaymentStatus(
      {required String username,
      required String password,
      required String clientId,
      required String orderId,
      required String paymentId}) async {
    final headers = <String, String>{
      'clientId': clientId,
      'username': username,
      'password': password,
      'Content-Type': 'application/json'
    };
    final body = <String, dynamic>{'order_id': orderId, 'paymentId': paymentId};
    final response = await post(getPaymentStatusUrl, headers: headers, body: json.encode(body));

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to get Payment Status for order_id ${orderId} paymentId ${paymentId};Incorrect response status: ${response.statusCode};');
    }

    final decodedBody = json.decode(response.body) as Map<String, dynamic>;
    final isSuccessful = decodedBody['Successful'] as bool? ?? false;

    if (!isSuccessful) {
      final msg = decodedBody['ErrorMessage'] as String ?? '';

      if (msg.isNotEmpty) {
        throw Exception(msg);
      }

      throw Exception(
          'Failed to get Payment Status for order_id ${orderId} paymentId ${paymentId}');
    }

    final data = decodedBody['Data'] as Map<String, dynamic>;
    return data['gift_card_id'] as int;
  }
}
