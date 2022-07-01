class OutputInfo {
	const OutputInfo(
		{this.fiatAmount,
		this.cryptoAmount,
		this.address,
		this.note,
		this.sendAll,
		this.extractedAddress,
		this.isParsedAddress,
		this.formattedCryptoAmount});

  	final String? fiatAmount;
  	final String? cryptoAmount;
  	final String? address;
  	final String? note;
  	final String? extractedAddress;
  	final bool? sendAll;
  	final bool? isParsedAddress;
  	final int? formattedCryptoAmount;
}