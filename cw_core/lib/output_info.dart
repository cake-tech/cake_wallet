class OutputInfo {
	const OutputInfo(
		{required this.address,
		required this.sendAll,
		required this.isParsedAddress,
    this.cryptoAmount,
		this.formattedCryptoAmount,
    this.fiatAmount,
    this.note,
    this.extractedAddress,});

  	final String? fiatAmount;
  	final String? cryptoAmount;
  	final String address;
  	final String? note;
  	final String? extractedAddress;
  	final bool sendAll;
  	final bool isParsedAddress;
  	final int? formattedCryptoAmount;
}