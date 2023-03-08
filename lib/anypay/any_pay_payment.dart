import 'package:cake_wallet/anypay/any_pay_chain.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/anypay/any_pay_payment_instruction.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/monero/monero.dart';

class AnyPayPayment {
	AnyPayPayment({
		required this.time,
		required this.expires,
		required this.memo,
		required this.paymentUrl,
		required this.paymentId,
		required this.chain,
		required this.network,
		required this.instructions});

	factory AnyPayPayment.fromMap(Map<String, dynamic> obj) {
		final instructions = (obj['instructions'] as List<dynamic>)
			.map((dynamic instruction) => AnyPayPaymentInstruction.fromMap(instruction as Map<String, dynamic>))
			.toList();
		return AnyPayPayment(
			time: DateTime.parse(obj['time'] as String),
			expires: DateTime.parse(obj['expires'] as String),
			memo: obj['memo'] as String,
			paymentUrl: obj['paymentUrl'] as String,
			paymentId: obj['paymentId'] as String,
			chain: obj['chain'] as String,
			network: obj['network'] as String,
			instructions: instructions);
	}

	final DateTime time;
	final DateTime expires;
	final String memo;
	final String paymentUrl;
	final String paymentId;
	final String chain;
	final String network;
	final List<AnyPayPaymentInstruction> instructions;

	String get totalAmount {
		final total = instructions
			.fold<int>(0, (int acc, instruction) => acc + instruction.outputs
				.fold<int>(0, (int outAcc, out) => outAcc + out.amount));
		switch (chain) {
			case AnyPayChain.xmr:
				return monero!.formatterMoneroAmountToString(amount: total);
			case AnyPayChain.btc:
				return bitcoin!.formatterBitcoinAmountToString(amount: total);
			case AnyPayChain.ltc:
				return bitcoin!.formatterBitcoinAmountToString(amount: total);
			default:
				return '';
		}
	}

	List<String> get outAddresses {
		return instructions
			.map((instruction) => instruction.outputs.map((out) => out.address))
			.expand((e) => e)
			.toList();
	}
}