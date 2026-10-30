part of 'spark_deposit_to_stable_bloc.dart';

@immutable
sealed class SparkDepositToStableState {}

/// Before [SparkDepositToStableBloc]'s constructor-fired `_Init` has resolved a stablecoin token and
/// its conversion limits.
final class SparkDepositToStableNotLoaded extends SparkDepositToStableState {}

/// [_Init] couldn't find a stablecoin Spark token on this wallet, or the wallet isn't a
/// Lightning-capable Bitcoin wallet in the first place - a real configuration error for this
/// flow (it's only ever opened from a stablecoin asset card), not something to swallow.
final class SparkDepositToStableUnavailable extends SparkDepositToStableState {
  SparkDepositToStableUnavailable(this.message);

  final String message;
}

/// Which asset the user is spending to acquire the other - [fromBitcoin] spends BTC/sats to
/// acquire the stablecoin token (the original direction), [toBitcoin] spends the token to
/// acquire BTC/sats (see `SparkDepositToStableBloc.prepareTokenToBitcoinConversion`/
/// `LightningWallet.prepareTokenToBitcoinConversion`).
enum ConversionDirection { fromBitcoin, toBitcoin }

/// Fields shared by every state once the token/limits are known.
sealed class SparkDepositToStableLoaded extends SparkDepositToStableState {
  SparkDepositToStableLoaded({
    required this.token,
    required this.limits,
    required this.reverseLimits,
    required this.amountText,
    required this.maxSlippageBps,
    required this.isFiatEntry,
    required this.direction,
  });

  final CryptoCurrency token;

  /// Limits for [ConversionDirection.fromBitcoin] (BTC -> token).
  final SparkConversionLimits limits;

  /// Limits for [ConversionDirection.toBitcoin] (token -> BTC) - a separate SDK call, and NOT
  /// simply [limits] with its fields swapped: the SDK's own from/to amounts are relative to the
  /// conversion's direction, but these two fields are each fixed to a specific asset regardless
  /// of direction (see `LightningWallet.fetchTokenToBitcoinConversionLimits`'s doc comment).
  final SparkConversionLimits reverseLimits;

  /// The limits for whichever direction is currently active.
  SparkConversionLimits get activeLimits =>
      direction == ConversionDirection.fromBitcoin ? limits : reverseLimits;

  /// Sats-denominated (or fiat-denominated when [isFiatEntry]) for [ConversionDirection.fromBitcoin],
  /// or token-denominated for [ConversionDirection.toBitcoin] - see [AmountChanged].
  final String amountText;
  final int maxSlippageBps;

  /// Only meaningful for [ConversionDirection.fromBitcoin] - [ConversionDirection.toBitcoin]'s
  /// amount is always token-denominated (see [amountText]).
  final bool isFiatEntry;
  final ConversionDirection direction;
}

/// The user can still edit the amount/slippage. [quote] is the live quote for the currently
/// entered amount, refreshed on every [AmountChanged]/[MaxSlippageChanged] - null until one
/// resolves (or after an amount/slippage edit invalidates the previous one). [isQuoting] is true
/// while a new quote is in flight. [error] surfaces validation failures (below minimum, invalid
/// amount) as well as real SDK errors from fetching a quote - never swallowed into an empty state.
final class SparkDepositToStableReady extends SparkDepositToStableLoaded {
  SparkDepositToStableReady({
    required super.token,
    required super.limits,
    required super.reverseLimits,
    required super.amountText,
    required super.maxSlippageBps,
    required super.isFiatEntry,
    required super.direction,
    this.quote,
    this.isQuoting = false,
    this.error,
  });

  final SparkConversionQuote? quote;
  final bool isQuoting;
  final String? error;
}

/// [ConversionRequested] is committing [quote].
final class SparkDepositToStableSubmitting extends SparkDepositToStableLoaded {
  SparkDepositToStableSubmitting({
    required super.token,
    required super.limits,
    required super.reverseLimits,
    required super.amountText,
    required super.maxSlippageBps,
    required super.isFiatEntry,
    required super.direction,
    required this.quote,
  });

  final SparkConversionQuote quote;
}

final class SparkDepositToStableSucceeded extends SparkDepositToStableLoaded {
  SparkDepositToStableSucceeded({
    required super.token,
    required super.limits,
    required super.reverseLimits,
    required super.amountText,
    required super.maxSlippageBps,
    required super.isFiatEntry,
    required super.direction,
    required this.quote,
    required this.paymentId,
  });

  final SparkConversionQuote quote;
  final String paymentId;
}

final class SparkDepositToStableFailed extends SparkDepositToStableLoaded {
  SparkDepositToStableFailed({
    required super.token,
    required super.limits,
    required super.reverseLimits,
    required super.amountText,
    required super.maxSlippageBps,
    required super.isFiatEntry,
    required super.direction,
    required this.quote,
    required this.error,
  });

  final SparkConversionQuote quote;
  final String error;
}
