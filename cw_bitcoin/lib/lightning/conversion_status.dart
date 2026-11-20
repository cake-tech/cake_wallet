/// A Stable Balance conversion's lifecycle state, as surfaced in a transaction's
/// `additionalInfo`'s `"conversionStatus"` key (see `LightningWallet` in `cw_bitcoin`, which
/// tags it from the Breez SDK's own `ConversionStatus`).
enum ConversionStatus { pending, completed, failed, refundNeeded, refunded }

class ConversionStatusUtils {
  /// Reads the conversion status tagged on a payment's `additionalInfo`, or null when the
  /// payment isn't a conversion at all (the common case - most payments never touch Stable
  /// Balance).
  static ConversionStatus? fromAdditionalInfo(Map<String, dynamic> additionalInfo) {
    final raw = additionalInfo["conversionStatus"];
    if (raw is! String) {
      return null;
    }

    for (final status in ConversionStatus.values) {
      if (status.name == raw) {
        return status;
      }
    }
    return null;
  }
}

/// Why the SDK changed a conversion's amount before running it.
enum ConversionAmountAdjustment { flooredToMinLimit, increasedToAvoidDust }
