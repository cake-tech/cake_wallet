class MoonPayPaymentMethod {
  MoonPayPaymentMethod({
    required this.type,
    required this.displayName,
    required this.iconUrl,
    required this.active,
    this.limitAmount,
    this.limitCurrencyCode,
  });

  factory MoonPayPaymentMethod.fromJson(Map<String, dynamic> json) {
    final availability = json["availability"] as Map<String, dynamic>? ?? {};
    final limits = json["limits"] as Map<String, dynamic>?;
    final perTransaction = limits?["perTransaction"] as Map<String, dynamic>?;

    return MoonPayPaymentMethod(
      type: json["type"] as String? ?? "",
      displayName: json["displayName"] as String? ?? "",
      iconUrl: json["iconUrl"] as String? ?? "",
      active: availability["active"] as bool? ?? false,
      limitAmount: (perTransaction?["limit"] as num?)?.toDouble(),
      limitCurrencyCode: perTransaction?["currencyCode"] as String?,
    );
  }

  final String type;
  final String displayName;
  final String iconUrl;
  final bool active;
  final double? limitAmount;
  final String? limitCurrencyCode;
}