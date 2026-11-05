part of "spark_stable_balance_send_bloc.dart";

@immutable
sealed class SparkStableBalanceSendEvent {}

/// The recipient or amount on the send page changed; an empty [address] or no [amount] clears
/// the quote.
final class SendDetailsChanged extends SparkStableBalanceSendEvent {
  SendDetailsChanged({required this.address, required this.amount, this.sendAll = false});

  final String address;

  /// Denominated in whatever currency is selected - sats, or the stablecoin.
  final Money? amount;

  /// Whether [amount] is the full available balance rather than a typed number - "ALL" leaves
  /// [amount] pre-resolved to that balance; this only tells the SDK to also treat fees as
  /// included, which is otherwise indistinguishable from a coincidentally-exact typed amount.
  final bool sendAll;
}
