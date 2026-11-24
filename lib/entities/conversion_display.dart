import "package:cake_wallet/entities/conversion_status.dart";
import "package:collection/collection.dart";
import "package:cw_core/format_fixed.dart";

/// How a Stable Balance conversion tagged on a transaction's `additionalInfo` (see
/// [ConversionStatusUtils]) is presented in history rows and detail pages.
class ConversionDisplayUtils {
  /// Whether this status needs the user's attention on the history row (a tap target instead of
  /// a plain timestamp) - a failed conversion or one still waiting on a refund.
  static bool needsAttention(ConversionStatus status) =>
      status == ConversionStatus.failed || status == ConversionStatus.refundNeeded;

  /// What a send the SDK funded by converting from a token cost in that token (e.g. "2 USDB"),
  /// or null for any other payment.
  static String? paidFromLabel(Map<String, dynamic> additionalInfo) {
    final ticker = additionalInfo["paidFromTicker"];
    final amount = BigInt.tryParse(additionalInfo["paidFromAmount"]?.toString() ?? "");
    final decimals = additionalInfo["paidFromDecimals"];
    if (ticker is! String || amount == null || decimals is! int) {
      return null;
    }
    return "${formatFixed(amount, decimals)} $ticker";
  }

  /// Builds a [ConversionDisplay] from a payment's `additionalInfo`, or null when it isn't a
  /// conversion, or (older stored transactions, from before the from/to asset tags existed)
  /// its status is known but the asset tags aren't - callers fall back to their pre-conversion-
  /// aware rendering in that case rather than showing a label with a missing asset name.
  static ConversionDisplay? displayFrom(Map<String, dynamic> additionalInfo) {
    final status = ConversionStatusUtils.fromAdditionalInfo(additionalInfo);
    final fromTicker = additionalInfo["conversionFromTicker"];
    final toTicker = additionalInfo["conversionToTicker"];
    final toIsToken = additionalInfo["conversionToIsToken"];
    if (status == null || fromTicker is! String || toTicker is! String || toIsToken is! bool) {
      return null;
    }
    return ConversionDisplay(
      status: status,
      fromTicker: fromTicker,
      toTicker: toTicker,
      toIsToken: toIsToken,
      fromAmount:
          _amount(additionalInfo, "conversionFromAmount", "conversionFromDecimals", fromTicker),
      fromFee: _amount(additionalInfo, "conversionFromFee", "conversionFromDecimals", fromTicker),
      toAmount: _amount(additionalInfo, "conversionToAmount", "conversionToDecimals", toTicker),
      toFee: _amount(additionalInfo, "conversionToFee", "conversionToDecimals", toTicker),
      amountAdjustment: ConversionAmountAdjustment.values
          .where((a) => a.name == additionalInfo["conversionAmountAdjustment"])
          .firstOrNull,
    );
  }

  /// A conversion step's amount formatted with its unit - sats for Bitcoin, otherwise the
  /// token's own decimals and ticker. Null when the step wasn't reported, or it's zero.
  static String? _amount(
    Map<String, dynamic> info,
    String amountKey,
    String decimalsKey,
    String ticker,
  ) {
    final raw = BigInt.tryParse(info[amountKey]?.toString() ?? "");
    final decimals = info[decimalsKey];
    if (raw == null || raw == BigInt.zero || decimals is! int) {
      return null;
    }
    if (ticker == "BTC") {
      return "$raw sats";
    }
    return "${formatFixed(raw, decimals)} $ticker";
  }
}

/// Which two assets a conversion is between and how far along it is - everything a history row
/// or payment detail page needs to render it, direction-agnostic (BTC -> token or token -> BTC).
class ConversionDisplay {
  const ConversionDisplay({
    required this.status,
    required this.fromTicker,
    required this.toTicker,
    required this.toIsToken,
    this.fromAmount,
    this.fromFee,
    this.toAmount,
    this.toFee,
    this.amountAdjustment,
  });

  final ConversionStatus status;
  final String fromTicker;
  final String toTicker;

  /// The conversion's two sides, formatted with units ("3569 sats", "2.991984 USDB"). Only known
  /// once the SDK attaches the full conversion details - null while a leg is still in flight.
  final String? fromAmount;
  final String? fromFee;
  final String? toAmount;
  final String? toFee;
  final ConversionAmountAdjustment? amountAdjustment;

  /// True when the destination asset is the stablecoin token (BTC -> token); false when it's
  /// Bitcoin/Lightning (token -> BTC). Always exactly one side is a token in this app - there's
  /// no token -> token conversion - so this alone determines both [toLabel] and [fromLabel].
  final bool toIsToken;

  /// The destination asset's display name - the token's own ticker, or "Lightning" for BTC.
  String get toLabel => toIsToken ? toTicker : "Lightning";

  /// The source asset's display name - the inverse of [toLabel].
  String get fromLabel => toIsToken ? "Lightning" : fromTicker;
}
