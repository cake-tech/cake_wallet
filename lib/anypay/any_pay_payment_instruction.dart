import 'package:flutter/foundation.dart';
import 'package:cake_wallet/anypay/any_pay_payment_instruction_output.dart';

class AnyPayPaymentInstruction {
	AnyPayPaymentInstruction({
		required this.type,
		required this.requiredFeeRate,
		required this.txKey,
		required this.txHash,
		required this.outputs});

	factory AnyPayPaymentInstruction.fromMap(Map<String, dynamic> obj) {
		final outputs = (obj['outputs'] as List<dynamic>)
			.map((dynamic out) =>
				AnyPayPaymentInstructionOutput.fromMap(out as Map<String, dynamic>))
			.toList();
		return AnyPayPaymentInstruction(
			type: obj['type'] as String,
			requiredFeeRate: obj['requiredFeeRate'] as int,
			txKey: obj['tx_key'] as bool,
			txHash: obj['tx_hash'] as bool,
			outputs: outputs);
	}

	static const transactionType = 'transaction';

	final String type;
	final int requiredFeeRate;
	final bool txKey;
	final bool txHash;
	final List<AnyPayPaymentInstructionOutput> outputs;
}