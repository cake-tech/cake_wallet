import 'package:cw_core/balance.dart';
import 'package:cw_minotari/minotari_amount_format.dart';

class MinotariBalance extends Balance {
  final int available;
  final int pendingIncoming;
  final int pendingOutgoing;

  MinotariBalance({
    required this.available,
    required this.pendingIncoming,
    required this.pendingOutgoing,
  }) : super(available, pendingIncoming + pendingOutgoing);

  @override
  String get formattedAvailableBalance => minotariAmountToString(amount: available);

  @override
  String get formattedAdditionalBalance =>
      minotariAmountToString(amount: pendingIncoming + pendingOutgoing);

  @override
  String get formattedUnAvailableBalance => minotariAmountToString(amount: pendingOutgoing);

  @override
  String get formattedFullAvailableBalance =>
      minotariAmountToString(amount: available + pendingIncoming);
}
