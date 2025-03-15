import 'package:cw_decred/amount_format.dart';
import 'package:cw_core/balance.dart';

class DecredBalance extends Balance {
  const DecredBalance({required this.confirmed, required this.unconfirmed, required this.frozen})
      : super(confirmed, unconfirmed);

  factory DecredBalance.zero() => DecredBalance(confirmed: 0, unconfirmed: 0, frozen: 0);

  final int confirmed;
  final int unconfirmed;
  final int frozen;

  @override
  String get formattedAvailableBalance => decredAmountToString(amount: confirmed - frozen);

  @override
  String get formattedAdditionalBalance => decredAmountToString(amount: unconfirmed);

  @override
  String get formattedUnAvailableBalance {
    final frozenFormatted = decredAmountToString(amount: frozen);
    return frozenFormatted == '0.0' ? '' : frozenFormatted;
  }
}
