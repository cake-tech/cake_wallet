import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/ionia/ionia_user_credentials.dart';
import 'package:cake_wallet/ionia/ionia_virtual_card.dart';

class IoniaApi {
	static const baseUri = 'apidev.dashdirect.org';
	static const pathPrefix = 'cake';
	static final createUserUri = Uri.https(baseUri, '/$pathPrefix/CreateUser');
	static final verifyEmailUri = Uri.https(baseUri, '/$pathPrefix/VerifyEmail');
	static final createCardUri = Uri.https(baseUri, '/$pathPrefix/CreateCard');
	static final getCardsUri = Uri.https(baseUri, '/$pathPrefix/GetCards');

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
}