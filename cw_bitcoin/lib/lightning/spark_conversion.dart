import "package:cw_bitcoin/lightning/conversion_status.dart";
import "package:cw_core/amount/money.dart";

/// Minimums reported by the Breez SDK's `fetchConversionLimits` for a Bitcoin <-> stablecoin
/// Spark token conversion, used to reject too-small amounts before requesting a quote. A null
/// field means the SDK didn't report that minimum, not that none exists - the conversion call
/// still enforces the real limit.
class SparkConversionLimits {
  const SparkConversionLimits({this.minAmountIn, this.minAmountOut});

  /// Minimum BTC (in sats) that must be converted, denominated in [CryptoCurrency.btcln].
  final Money? minAmountIn;

  /// Minimum token amount the conversion must produce, denominated in the target token's own
  /// currency.
  final Money? minAmountOut;
}

/// A live quote for a one-off Bitcoin -> stablecoin Spark token conversion, returned by
/// [Bitcoin.prepareBitcoinToStableConversion] (see `lib/bitcoin/bitcoin.dart`). Deliberately not
/// modeled as a [PendingTransaction] - a conversion has two currencies (BTC in, token out) that a
/// single amount/fee pair can't represent, and this is a Breez-conversion-specific shape that has
/// no business being on the shared [PendingTransaction] mixin every coin in the app uses.
class SparkConversionQuote {
  const SparkConversionQuote({
    required this.amountIn,
    required this.amountOut,
    required this.fee,
    required this.commit,
  });

  /// The BTC amount actually taken as input, denominated in [CryptoCurrency.btcln] - may differ
  /// slightly from what was requested (see the SDK's `AmountAdjustmentReason`).
  final Money amountIn;

  /// The token amount the conversion is expected to produce, denominated in the target token's
  /// own currency.
  final Money amountOut;

  /// The conversion fee, denominated in the target token's own currency.
  final Money fee;

  /// Commits the already-prepared conversion (a Breez `sendPayment` call), returning the
  /// resulting payment id. Calling this more than once re-sends the same prepared payment - the
  /// caller is responsible for only invoking it once per quote.
  final Future<String> Function() commit;
}

/// The stablecoin -> sats conversion Stable Balance adds in front of a Lightning send when the
/// sats balance can't cover it.
class StableBalanceSendConversion {
  const StableBalanceSendConversion({
    required this.amountIn,
    required this.amountOut,
    required this.fee,
    this.amountAdjustment,
  });

  /// The token spent, fee included, in the token's own currency.
  final Money amountIn;

  /// The sats the conversion produces for the payment, in [CryptoCurrency.btcln].
  final Money amountOut;

  /// The conversion fee, in the token's own currency - already part of [amountIn].
  final Money fee;

  final ConversionAmountAdjustment? amountAdjustment;
}

/// A prepared (not sent) Lightning payment: what the recipient gets, what it costs, and the
/// Stable Balance conversion funding it, if any.
class LightningSendQuote {
  const LightningSendQuote({
    required this.amount,
    required this.fee,
    this.conversion,
    this.isOnChain = false,
  });

  /// The sats the recipient gets.
  final Money amount;

  /// The recipient is paid on-chain (a Bitcoin address) rather than over Lightning or as a Spark
  /// transfer.
  final bool isOnChain;

  /// The Lightning/Spark fee, in sats.
  final Money fee;

  final StableBalanceSendConversion? conversion;
}
