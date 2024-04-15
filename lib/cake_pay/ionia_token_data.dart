import 'package:flutter/foundation.dart';
import 'dart:convert';

class IoniaTokenData {
	IoniaTokenData({required this.accessToken, required this.tokenType, required this.expiredAt});

	factory IoniaTokenData.fromJson(String source) {
		final decoded = json.decode(source) as Map<String, dynamic>;
		final accessToken = decoded['access_token'] as String;
		final expiresIn = decoded['expires_in'] as int;
		final tokenType = decoded['token_type'] as String;
		final expiredAtInMilliseconds = decoded['expired_at'] as int;
		DateTime expiredAt;

		if (expiredAtInMilliseconds != null) {
			expiredAt = DateTime.fromMillisecondsSinceEpoch(expiredAtInMilliseconds);
		} else {
			expiredAt = DateTime.now().add(Duration(seconds: expiresIn));
		}

		return IoniaTokenData(
			accessToken: accessToken,
			tokenType: tokenType,
			expiredAt: expiredAt);
	}

	final String accessToken;
	final String tokenType;
	final DateTime expiredAt;

	bool get isExpired => DateTime.now().isAfter(expiredAt);

	@override
	String toString() => '$tokenType $accessToken';

	String toJson() {
		return json.encode(<String, dynamic>{
			'access_token': accessToken,
			'token_type': tokenType,
			'expired_at': expiredAt.millisecondsSinceEpoch
		});
	}
}