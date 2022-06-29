import 'dart:convert';
import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/ionia/ionia_order.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/ionia/ionia_user_credentials.dart';
import 'package:cake_wallet/ionia/ionia_virtual_card.dart';
import 'package:cake_wallet/ionia/ionia_category.dart';

class IoniaApi {
	static const baseUri = 'apidev.dashdirect.org';
	static const pathPrefix = 'cake';
	static final createUserUri = Uri.https(baseUri, '/$pathPrefix/CreateUser');
	static final verifyEmailUri = Uri.https(baseUri, '/$pathPrefix/VerifyEmail');
	static final createCardUri = Uri.https(baseUri, '/$pathPrefix/CreateCard');
	static final getCardsUri = Uri.https(baseUri, '/$pathPrefix/GetCards');
	static final getMerchantsUrl = Uri.https(baseUri, '/$pathPrefix/GetMerchants');
	static final getMerchantsByFilterUrl = Uri.https(baseUri, '/$pathPrefix/GetMerchantsByFilter');
  	static final getPurchaseMerchantsUrl = Uri.https(baseUri, '/$pathPrefix/PurchaseGiftCard');

	// Create user

	Future<String> createUser(String email, {@required String clientId}) async {
		final headers = <String, String>{'clientId': clientId};
		final query = <String, String>{'emailAddress': email};
		final uri = createUserUri.replace(queryParameters: query);
		final response = await put(uri, headers: headers);
		
		if (response.statusCode != 200) {
			// throw exception
			return null;
		}

		final bodyJson = json.decode(response.body) as Map<String, Object>;
		final data = bodyJson['Data'] as Map<String, Object>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(data['ErrorMessage'] as String);
		}

		return data['username'] as String;
	}

	// Verify email

	Future<IoniaUserCredentials> verifyEmail({
		@required String username,
		@required String code,
		@required String clientId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username};
		final query = <String, String>{'verificationCode': code};
		final uri = verifyEmailUri.replace(queryParameters: query);
		final response = await put(uri, headers: headers);

		if (response.statusCode != 200) {
			// throw exception
			return null;
		}

		final bodyJson = json.decode(response.body) as Map<String, Object>;
		final data = bodyJson['Data'] as Map<String, Object>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(data['ErrorMessage'] as String);
		}
		
		final password = data['password'] as String;
		return IoniaUserCredentials(username, password);
	}

	// Get virtual card

	Future<IoniaVirtualCard> getCards({
		@required String username,
		@required String password,
		@required String clientId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password};
		final response = await post(getCardsUri, headers: headers);

		if (response.statusCode != 200) {
			// throw exception
			return null;
		}

		final bodyJson = json.decode(response.body) as Map<String, Object>;
		final data = bodyJson['Data'] as Map<String, Object>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(data['message'] as String);
		}

		final virtualCard = data['VirtualCard'] as Map<String, Object>;
		return IoniaVirtualCard.fromMap(virtualCard);
	}

	// Create virtual card

	Future<IoniaVirtualCard> createCard({
		@required String username,
		@required String password,
		@required String clientId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password};
		final response = await post(createCardUri, headers: headers);

		if (response.statusCode != 200) {
			// throw exception
			return null;
		}

		final bodyJson = json.decode(response.body) as Map<String, Object>;
		final data = bodyJson['Data'] as Map<String, Object>;
		final isSuccessful = bodyJson['Successful'] as bool;

		if (!isSuccessful) {
			throw Exception(data['message'] as String);
		}

		return IoniaVirtualCard.fromMap(data);
	}

	// Get Merchants

	Future<List<IoniaMerchant>> getMerchants({
		@required String username,
		@required String password,
		@required String clientId}) async {
	    final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password};
		final response = await post(getMerchantsUrl, headers: headers);

		if (response.statusCode != 200) {
			return [];
		}

		final decodedBody = json.decode(response.body) as Map<String, dynamic>;
		final isSuccessful = decodedBody['Successful'] as bool ?? false;
    
		if (!isSuccessful) {
			return [];
		}

		final data = decodedBody['Data'] as List<dynamic>;
		return data.map((dynamic e) {
			final element = e as Map<String, dynamic>;
			return IoniaMerchant.fromJsonMap(element);
		}).toList();
	}

	// Get Merchants By Filter

	Future<List<IoniaMerchant>> getMerchantsByFilter({
		@required String username,
		@required String password,
		@required String clientId,
		String search,
		List<IoniaCategory> categories,
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
		final isSuccessful = decodedBody['Successful'] as bool ?? false;

		if (!isSuccessful) {
			return [];
		}

		final data = decodedBody['Data'] as List<dynamic>;
		return data.map((dynamic e) {
			final element = e['Merchant'] as Map<String, dynamic>;
			return IoniaMerchant.fromJsonMap(element);
		}).toList();
	}

	// Purchase Gift Card

	Future<IoniaOrder> purchaseGiftCard({
		@required String merchId,
		@required double amount,
		@required String currency,
		@required String username,
		@required String password,
		@required String clientId}) async {
		final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password,
			'Content-Type': 'application/json'};
		final body = <String, dynamic>{
			'Amount': amount,
		    'Currency': currency,
		    'MerchantId': merchId};
		final response = await post(getPurchaseMerchantsUrl, headers: headers, body: json.encode(body));

    	if (response.statusCode != 200) {
			return null;
		}

    	final decodedBody = json.decode(response.body) as Map<String, dynamic>;
		final isSuccessful = decodedBody['Successful'] as bool ?? false;
    
		if (!isSuccessful) {
			return null;
		}

		final data = decodedBody['Data'] as Map<String, dynamic>;
    	return IoniaOrder.fromMap(data);
	}

	// Get Current User Gift Card Summaries

	Future<List<IoniaMerchant>> getCurrentUserGiftCardSummaries({
		@required String username,
		@required String password,
		@required String clientId}) async {
	    final headers = <String, String>{
			'clientId': clientId,
			'username': username,
			'password': password};
		final response = await post(getMerchantsUrl, headers: headers);

		if (response.statusCode != 200) {
			return [];
		}

		final decodedBody = json.decode(response.body) as Map<String, dynamic>;
		final isSuccessful = decodedBody['Successful'] as bool ?? false;
    
		if (!isSuccessful) {
			return [];
		}

		final data = decodedBody['Data'] as List<dynamic>;
		return data.map((dynamic e) {
			final element = e as Map<String, dynamic>;
			return IoniaMerchant.fromJsonMap(element);
		}).toList();
	}
}