import 'dart:convert';
import 'package:http/http.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/anypay/any_pay_payment.dart';

class AnyPayApi {
	static const contentTypePaymentRequest = 'application/payment-request';
	static const xPayproVersion = '2';

	static String chainByScheme(String scheme) {
		switch (scheme.toLowerCase()) {
			case 'monero':
				return CryptoCurrency.xmr.title;
			default:
				return '';
		}
	}

	static CryptoCurrency currencyByScheme(String scheme) {
		switch (scheme.toLowerCase()) {
			case 'monero':
				return CryptoCurrency.xmr;
			default:
				return null;
		}
	}

	Future<AnyPayPayment> pay(String uri) async {
		final fragments = uri.split(':?r=');
		final scheme = fragments.first;
		final url = fragments[1];
  		final headers = <String, String>{
  			'Content-Type': contentTypePaymentRequest,
  			'X-Paypro-Version': xPayproVersion,
  			'Accept': '*/*',};
		final body = <String, dynamic>{
			'chain': chainByScheme(scheme),
			'currency': currencyByScheme(scheme).title};
		final response = await post(url, headers: headers, body: utf8.encode(json.encode(body)));

    	if (response.statusCode != 200) {
			return null;
		}

    	final decodedBody = json.decode(response.body) as Map<String, dynamic>;
    	return AnyPayPayment.fromMap(decodedBody);
	}
}