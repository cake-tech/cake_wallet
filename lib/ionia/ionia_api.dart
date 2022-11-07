import 'dart:convert';
import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/ionia/ionia_order.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/ionia/ionia_user_credentials.dart';
import 'package:cake_wallet/ionia/ionia_virtual_card.dart';
import 'package:cake_wallet/ionia/ionia_category.dart';
import 'package:cake_wallet/ionia/ionia_gift_card.dart';

class IoniaApi {
	static const baseUri = 'api.ionia.io';
	static const pathPrefix = 'cake';
	static const requestedUUIDHeader = 'requestedUUID';
	static final createUserUri = Uri.https(baseUri, '/$pathPrefix/CreateUser');
	static final verifyEmailUri = Uri.https(baseUri, '/$pathPrefix/VerifyEmail');
	static final signInUri = Uri.https(baseUri, '/$pathPrefix/SignIn');
	static final createCardUri = Uri.https(baseUri, '/$pathPrefix/CreateCard');
	static final getCardsUri = Uri.https(baseUri, '/$pathPrefix/GetCards');
	static final getMerchantsUrl = Uri.https(baseUri, '/$pathPrefix/GetMerchants');
	static final getMerchantsByFilterUrl = Uri.https(baseUri, '/$pathPrefix/GetMerchantsByFilter');
  	static final getPurchaseMerchantsUrl = Uri.https(baseUri, '/$pathPrefix/PurchaseGiftCard');
  	static final getCurrentUserGiftCardSummariesUrl = Uri.https(baseUri, '/$pathPrefix/GetCurrentUserGiftCardSummaries');
  	static final changeGiftCardUrl = Uri.https(baseUri, '/$pathPrefix/ChargeGiftCard');
  	static final getGiftCardUrl = Uri.https(baseUri, '/$pathPrefix/GetGiftCard');
  	static final getPaymentStatusUrl = Uri.https(baseUri, '/$pathPrefix/PaymentStatus');

	// Create user

	Future<String> createUser(String email, {required String clientId}) async {
		final headers = <String, String>{'clientId': clientId};
		final query = <String, String>{'emailAddress': email};
		final uri = createUserUri.replace(queryParameters: query);
		final response = await put(uri, headers: headers);
		
		if (response.statusCode != 200) {
			throw Exception('Unexpected http status: ${response.statusCode}');
		}

		final bodyJson = json.decode(response.body) as Map<String, dynamic>;
		final data = bodyJson['Data'] as Map<String, dynamic>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(data['ErrorMessage'] as String);
		}

		return data['username'] as String;
	}

	// Verify email

	Future<IoniaUserCredentials> verifyEmail({
		required String email,
		required String code,
		required String clientId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'EmailAddress': email};
		final query = <String, String>{'verificationCode': code};
		final uri = verifyEmailUri.replace(queryParameters: query);
		final response = await put(uri, headers: headers);

		if (response.statusCode != 200) {
			throw Exception('Unexpected http status: ${response.statusCode}');
		}

		final bodyJson = json.decode(response.body) as Map<String, dynamic>;
		final data = bodyJson['Data'] as Map<String, dynamic>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(bodyJson['ErrorMessage'] as String);
		}
		
		final password = data['password'] as String;
		final username = data['username'] as String;
		return IoniaUserCredentials(username, password);
	}

	// Sign In

	Future<void> signIn(String email, {required String clientId}) async {
		final headers = <String, String>{'clientId': clientId};
		final query = <String, String>{'emailAddress': email};
		final uri = signInUri.replace(queryParameters: query);
		final response = await put(uri, headers: headers);
		
		if (response.statusCode != 200) {
		  throw Exception('Unexpected http status: ${response.statusCode}');
		}

		final bodyJson = json.decode(response.body) as Map<String, dynamic>;
		final data = bodyJson['Data'] as Map<String, dynamic>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(data['ErrorMessage'] as String);
		}
	}

	// Get virtual card

	Future<IoniaVirtualCard> getCards({
		required String username,
		required String password,
		required String clientId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password};
		final response = await post(getCardsUri, headers: headers);

		if (response.statusCode != 200) {
		  throw Exception('Unexpected http status: ${response.statusCode}');
		}

		final bodyJson = json.decode(response.body) as Map<String, dynamic>;
		final data = bodyJson['Data'] as Map<String, dynamic>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(data['message'] as String);
		}

		final virtualCard = data['VirtualCard'] as Map<String, dynamic>;
		return IoniaVirtualCard.fromMap(virtualCard);
	}

	// Create virtual card

	Future<IoniaVirtualCard> createCard({
		required String username,
		required String password,
		required String clientId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password};
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

		return IoniaVirtualCard.fromMap(data);
	}

	// Get Merchants

	Future<List<IoniaMerchant>> getMerchants({
		required String username,
		required String password,
		required String clientId}) async {
	    final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password};
		final response = await post(getMerchantsUrl, headers: headers);

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
				final element = item as Map<String, dynamic>;
				merch.add(IoniaMerchant.fromJsonMap(element));
			} catch(_) {} 
    }

    return merch;
	}

	// Get Merchants By Filter

	Future<List<IoniaMerchant>> getMerchantsByFilter({
		required String username,
		required String password,
		required String clientId,
		String? search,
		List<IoniaCategory>? categories,
		int merchantFilterType = 0}) async {
		// MerchantFilterType: {All = 0, Nearby = 1, Popular = 2, Online = 3, MyFaves = 4, Search = 5}
	    
	    final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password,
			'Content-Type': 'application/json'};
		final body = <String, dynamic>{'MerchantFilterType': merchantFilterType};

		if (search != null) {
			body['SearchCriteria'] = search;
		}

		if (categories != null) {
			body['Categories'] = categories
				.map((e) => e.ids)
				.expand((e) => e)
				.toList();
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
			} catch(_) {}
    }
		
    return merch;
	}

	// Purchase Gift Card

	Future<IoniaOrder> purchaseGiftCard({
		required String requestedUUID,
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
			'Content-Type': 'application/json'};
		final body = <String, dynamic>{
			'Amount': amount,
		    'Currency': currency,
		    'MerchantId': merchId};
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

	Future<List<IoniaGiftCard>> getCurrentUserGiftCardSummaries({
		required String username,
		required String password,
		required String clientId}) async {
	    final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password};
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
			} catch(_) {}
    }

    return cards;
	}

	// Charge Gift Card

	Future<void> chargeGiftCard({
		required String username,
		required String password,
		required String clientId,
		required int giftCardId,
		required double amount}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password,
			'Content-Type': 'application/json'};
		final body = <String, dynamic>{
			'Id': giftCardId,
			'Amount': amount};
		final response = await post(
			changeGiftCardUrl,
			headers: headers,
			body: json.encode(body));

		if (response.statusCode != 200) {
			throw Exception('Failed to update Gift Card with ID ${giftCardId};Incorrect response status: ${response.statusCode};');
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

	Future<IoniaGiftCard> getGiftCard({
		required String username,
		required String password,
		required String clientId,
		required int id}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password,
			'Content-Type': 'application/json'};
		final body = <String, dynamic>{'Id': id};
		final response = await post(
			getGiftCardUrl,
			headers: headers,
			body: json.encode(body));

		if (response.statusCode != 200) {
			throw Exception('Failed to get Gift Card with ID ${id};Incorrect response status: ${response.statusCode};');
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

	Future<int> getPaymentStatus({
		required String username,
		required String password,
		required String clientId,
		required String orderId,
		required String paymentId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password,
			'Content-Type': 'application/json'};
		final body = <String, dynamic>{
			'order_id': orderId,
			'paymentId': paymentId};
		final response = await post(
			getPaymentStatusUrl,
			headers: headers,
			body: json.encode(body));

		if (response.statusCode != 200) {
			throw Exception('Failed to get Payment Status for order_id ${orderId} paymentId ${paymentId};Incorrect response status: ${response.statusCode};');
		}

		final decodedBody = json.decode(response.body) as Map<String, dynamic>;
		final isSuccessful = decodedBody['Successful'] as bool? ?? false;

		if (!isSuccessful) {
			final msg = decodedBody['ErrorMessage'] as String ?? '';

			if (msg.isNotEmpty) {
				throw Exception(msg);
			}

			throw Exception('Failed to get Payment Status for order_id ${orderId} paymentId ${paymentId}');
		}

		final data = decodedBody['Data'] as Map<String, dynamic>;
		return data['gift_card_id'] as int;
	}
}