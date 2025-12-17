import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';

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
  String get formattedAvailableBalance => _formatBalance(available);

  @override
  String get formattedAdditionalBalance => _formatBalance(pendingIncoming + pendingOutgoing);

  String _formatBalance(int balance) {
    // Minotari uses 6 decimal places (microTari)
    final wholePart = balance ~/ 1000000;
    final fractionalPart = balance % 1000000;
    return '$wholePart.${fractionalPart.toString().padLeft(6, '0')}';
  }
}
