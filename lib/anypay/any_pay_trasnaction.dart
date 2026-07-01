class AnyPayTransaction {
	const AnyPayTransaction(this.tx, {required this.id, required this.key});

	final String tx;
	final String id;
	final String? key;
}