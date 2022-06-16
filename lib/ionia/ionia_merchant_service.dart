import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/ionia/ionia_token_service.dart';

class IoniaMerchantService {
	IoniaMerchantService(this._tokenService, {@required this.isDevEnv});

	static String devApiUrl = "https://apidev.dashdirect.org/partner";

	final bool isDevEnv;

	final TokenService _tokenService;

	String get apiUrl => isDevEnv ? devApiUrl : '';

	String get getMerchantsUrl => '$apiUrl/GetMerchants';

	Future<List<IoniaMerchant>> getMerchants() async {
		final token = await _tokenService.getToken();
    // FIX ME: remove hardcoded values
		final headers = <String, String>{
			'Authorization': token.toString(),
			'firstName': 'cake',
			'lastName': 'cake',
			'email': 'cake@test'};
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

	Future<void> purchaseGiftCard() async {

	}
}