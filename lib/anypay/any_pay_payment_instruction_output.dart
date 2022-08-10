class AnyPayPaymentInstructionOutput {
	const AnyPayPaymentInstructionOutput(this.address, this.amount);

	factory AnyPayPaymentInstructionOutput.fromMap(Map<String, dynamic> obj) {
		return AnyPayPaymentInstructionOutput(obj['address'] as String, obj['amount'] as int);
	}

	final String address;
	final int amount;
}