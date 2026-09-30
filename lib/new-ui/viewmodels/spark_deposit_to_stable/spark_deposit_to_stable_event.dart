part of 'spark_deposit_to_stable_bloc.dart';

@immutable
sealed class SparkDepositToStableEvent {}

final class _Init extends SparkDepositToStableEvent {}

/// The text as typed into the amount field, denominated in sats or in the user's fiat currency
/// depending on [SparkDepositToStableLoaded.isFiatEntry] at the time. The Bloc estimates the
/// resulting stablecoin token amount from this (the Breez SDK's `prepareSendPayment`/
/// `ConversionType.fromBitcoin` only ever accepts a target-token amount, never a sats amount,
/// directly - see [SparkDepositToStableBloc.parseSatsOrFiatAmount]/`_estimateTokenAmount`).
final class AmountChanged extends SparkDepositToStableEvent {
  AmountChanged(this.amountText);

  final String amountText;
}

final class MaxSlippageChanged extends SparkDepositToStableEvent {
  MaxSlippageChanged(this.bps);

  final int bps;
}

/// Flips [SparkDepositToStableLoaded.isFiatEntry] (sats <-> the user's fiat currency), converting the
/// currently typed amount to its equivalent in the new denomination. Mirrors `Output.isFiatEntry`
/// in the regular Send flow. A no-op while [SparkDepositToStableBloc.isFiatDisabled].
final class FiatEntryToggled extends SparkDepositToStableEvent {}

/// Switches which asset is being spent to acquire the other - picked from the amount field's own
/// currency selector (BTC/sats or the stablecoin token). Resets the amount field: the same typed
/// number under a different asset/direction is a different real amount, and there's no sats<->token
/// rate to convert it with client-side without first fetching a quote in the new direction (see
/// `SparkDepositToStableBloc._estimateTokenAmount`/`_estimateSatsAmount`).
final class DirectionChanged extends SparkDepositToStableEvent {
  DirectionChanged(this.direction);

  final ConversionDirection direction;
}

/// The user tapped Continue/Confirm to actually commit the currently-quoted conversion.
final class ConversionRequested extends SparkDepositToStableEvent {}
