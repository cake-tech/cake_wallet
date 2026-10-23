part of "spark_stable_balance_send_bloc.dart";

@immutable
sealed class SparkStableBalanceSendState {}

/// No recipient or amount yet, so there's nothing to quote.
final class SparkStableBalanceSendNotLoaded extends SparkStableBalanceSendState {}

final class SparkStableBalanceSendQuoting extends SparkStableBalanceSendState {}

final class SparkStableBalanceSendQuoted extends SparkStableBalanceSendState {
  SparkStableBalanceSendQuoted(this.quote);

  final LightningSendQuote quote;
}

final class SparkStableBalanceSendQuoteFailed extends SparkStableBalanceSendState {
  SparkStableBalanceSendQuoteFailed(this.message);

  final String message;
}
