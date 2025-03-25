class OpenCryptoPayRequest {
  final String address;
  final BigInt amount;
  final String receiverName;
  final int expiry;
  final String callbackUrl;
  final String quote;

  OpenCryptoPayRequest({
    required this.address,
    required this.amount,
    required this.receiverName,
    required this.expiry,
    required this.callbackUrl,
    required this.quote,
  });
}

