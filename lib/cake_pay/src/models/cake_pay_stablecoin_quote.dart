class CakePayStablecoinQuote {
  const CakePayStablecoinQuote({
    required this.paymentMethod,
    required this.chain,
    required this.chainName,
    required this.address,
    required this.amount,
    required this.fee,
    required this.paymentRequest,
    this.contract,
    this.offeredUntil,
  });

  factory CakePayStablecoinQuote.fromMap(Map<String, dynamic> map) {
    final offeredUntil = map["offered_until"] as int;

    return CakePayStablecoinQuote(
      paymentMethod: map["payment_method"] as String,
      chain: map["chain"] as String,
      chainName: map["chain_name"] as String,
      address: map["address"] as String,
      amount: map["amount"] as String,
      fee: map["fee"] as String,
      paymentRequest: map["payment_request"] as String,
      contract: map["contract"] as String?,
      offeredUntil: offeredUntil > 0 ? DateTime.fromMillisecondsSinceEpoch(offeredUntil) : null,
    );
  }

  final String paymentMethod;
  final String chain;
  final String chainName;
  final String address;
  final String amount;
  final String fee;
  final String paymentRequest;
  final String? contract;
  final DateTime? offeredUntil;
}
