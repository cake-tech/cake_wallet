import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cake_wallet/ionia/ionia_token_data.dart';
import 'package:cake_wallet/.secrets.g.dart';

String basicAuth(String username, String password) =>
	'Basic ' + base64Encode(utf8.encode('$username:$password'));

abstract class TokenService {
	TokenService(this.flutterSecureStorage);

	String get serviceName;
	String get oauthUrl;
	final FlutterSecureStorage flutterSecureStorage;

	String get _storeKey => '${serviceName}_oauth_token';

	Future<IoniaTokenData> getToken() async {
		final storedTokenJson = await flutterSecureStorage.read(key: _storeKey);
		IoniaTokenData token;

		if (storedTokenJson != null) {
			token = IoniaTokenData.fromJson(storedTokenJson);
		} else {
			token = await _fetchNewToken();
			await _storeToken(token);
		}

		if (token.isExpired) {
			token = await _fetchNewToken();
			await _storeToken(token);
		}

		return token;
	}

	Future<IoniaTokenData> _fetchNewToken() async {
		final basic = basicAuth(ioniaClientId, ioniaClientSecret);
		final body = <String, String>{'grant_type': 'client_credentials', 'scope': 'cake_dev'};
		final response = await post(
			oauthUrl,
			headers: <String, String>{
				'Authorization': basic,
				'Content-Type': 'application/x-www-form-urlencoded'},
			encoding: Encoding.getByName('utf-8'),
			body: body);

		if (response.statusCode != 200) {
			// throw exception
			return null;
		}

		return IoniaTokenData.fromJson(response.body);
	}

	Future<void> _storeToken(IoniaTokenData token) async {
		await flutterSecureStorage.write(key: _storeKey, value: token.toJson());
	}	

}

class IoniaTokenService extends TokenService {
	IoniaTokenService(FlutterSecureStorage flutterSecureStorage)
		: super(flutterSecureStorage);

	@override
	String get serviceName => 'Ionia';

	@override
	String get oauthUrl => 'https://auth.craypay.com/connect/token';
}