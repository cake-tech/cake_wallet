import 'package:flutter/foundation.dart';
import 'package:cake_wallet/anypay/any_pay_trasnaction.dart';

class AnyPayPaymentCommittedInfo {
	const AnyPayPaymentCommittedInfo({
		required this.uri,
		required this.currency,
		required this.chain,
		required this.transactions,
		required this.memo});

	final String uri;
	final String currency;
	final String chain;
	final List<AnyPayTransaction> transactions;
	final String memo;
}