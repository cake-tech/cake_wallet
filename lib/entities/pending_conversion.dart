/// A Stable Conversion this app itself just committed (via `SparkDepositToStableBloc`), shown in
/// history immediately - before the wallet's own transaction sync has picked up the real SDK
/// payment record - so a completed conversion isn't invisible until the next background sync.
/// Presentation-only and short-lived: never the source of truth for whether the conversion
/// actually succeeded (the real transaction record is), and removed once that real record shows
/// up (see `PendingConversionStore.reconcile`).
class PendingConversion {
  const PendingConversion({
    required this.paymentId,
    required this.walletId,
    required this.fromTicker,
    required this.toTicker,
    required this.toIsToken,
    required this.amountOutBaseUnits,
    required this.amountOutDecimals,
    required this.createdAt,
    this.paymentHash,
  });

  /// The SDK payment id returned by `SparkConversionQuote.commit()` - the primary key used to
  /// find the matching real transaction once it syncs in.
  final String paymentId;

  /// A fallback matching key for the self-transfer twin the SDK may record under a *different*
  /// payment id than [paymentId] (see `ConversionTwinCollapser`) - null until a real transaction
  /// tags it, at which point [PendingConversionStore.reconcile] can still only match by
  /// [paymentId] (this field exists on the model for symmetry with [ConversionTwinCollapser]'s
  /// own matching keys, in case a future SDK version exposes it before commit).
  final String? paymentHash;

  final String walletId;
  final String fromTicker;
  final String toTicker;
  final bool toIsToken;

  /// The destination amount, as it will render once real - kept as a base-unit string (not a
  /// [Currency]-bearing `Money`) so this model has no dependency on which package defines the
  /// destination's currency.
  final String amountOutBaseUnits;
  final int amountOutDecimals;

  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        "paymentId": paymentId,
        "paymentHash": paymentHash,
        "walletId": walletId,
        "fromTicker": fromTicker,
        "toTicker": toTicker,
        "toIsToken": toIsToken,
        "amountOutBaseUnits": amountOutBaseUnits,
        "amountOutDecimals": amountOutDecimals,
        "createdAt": createdAt.toIso8601String(),
      };

  static PendingConversion? fromJson(Map<String, dynamic> json) {
    try {
      return PendingConversion(
        paymentId: json["paymentId"] as String,
        paymentHash: json["paymentHash"] as String?,
        walletId: json["walletId"] as String,
        fromTicker: json["fromTicker"] as String,
        toTicker: json["toTicker"] as String,
        toIsToken: json["toIsToken"] as bool,
        amountOutBaseUnits: json["amountOutBaseUnits"] as String,
        amountOutDecimals: json["amountOutDecimals"] as int,
        createdAt: DateTime.parse(json["createdAt"] as String),
      );
    } catch (_) {
      return null;
    }
  }
}
