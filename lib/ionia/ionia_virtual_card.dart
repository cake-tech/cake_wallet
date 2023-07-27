class IoniaVirtualCard {
	IoniaVirtualCard({
		required this.token,
		required this.createdAt,
		required this.lastFour,
		required this.state,
		required this.pan,
		required this.cvv,
		required this.expirationMonth,
		required this.expirationYear,
		required this.fundsLimit,
		required this.spendLimit});
	
	factory IoniaVirtualCard.fromMap(Map<String, dynamic> source) {
		final created = source['created'] as String;
		final createdAt = DateTime.tryParse(created);

		return IoniaVirtualCard(
			token: source['token'] as String,
			createdAt: createdAt,
			lastFour: source['lastFour'] as String,
			state: source['state'] as String,
			pan: source['pan'] as String,
			cvv: source['cvv'] as String,
			expirationMonth: source['expirationMonth'] as String,
			expirationYear: source['expirationYear'] as String,
			fundsLimit: source['FundsLimit'] as double,
			spendLimit: source['spend_limit'] as double);
	}

	final String token;
	final String lastFour;
	final String state;
	final String pan;
	final String cvv;
	final String expirationMonth;
	final String expirationYear;
	final DateTime? createdAt;
	final double fundsLimit;
	final double spendLimit;
}