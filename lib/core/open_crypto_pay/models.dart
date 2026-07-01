class OpenCryptoPayRequest {
  final String receiverName;
  final int expiry;
  final String callbackUrl;
  final String quote;
  final Map<String, List<OpenCryptoPayQuoteAsset>> methods;

  OpenCryptoPayRequest({
    required this.receiverName,
    required this.expiry,
    required this.callbackUrl,
    required this.quote,
    required this.methods,
  });
}

class OpenCryptoPayQuoteAsset {
  final String symbol;
  final String amount;

  const OpenCryptoPayQuoteAsset(this.symbol, this.amount);

  OpenCryptoPayQuoteAsset.fromJson(Map<String, dynamic> json)
      : symbol = json['asset'] as String,
        amount = json['amount'] as String;
}
