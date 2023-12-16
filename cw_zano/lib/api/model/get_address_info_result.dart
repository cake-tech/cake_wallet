class GetAddressInfoResult {
  final bool valid;
  final bool auditable;
  final bool paymentId;
  final bool wrap;

  GetAddressInfoResult(
      {required this.valid, required this.auditable, required this.paymentId, required this.wrap});

  factory GetAddressInfoResult.fromJson(Map<String, dynamic> json) => GetAddressInfoResult(
        valid: json['valid'] as bool,
        auditable: json['auditable'] as bool,
        paymentId: json['payment_id'] as bool,
        wrap: json['wrap'] as bool,
      );
}
