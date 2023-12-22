import 'package:cw_decred/amount_format.dart';
import 'package:cw_core/balance.dart';

class DecredBalance extends Balance {
  const DecredBalance({required this.confirmed, required this.unconfirmed})
      : super(confirmed, unconfirmed);

  final int confirmed;
  final int unconfirmed;

  @override
  String get formattedAvailableBalance =>
      decredAmountToString(amount: confirmed);

  @override
  String get formattedAdditionalBalance =>
      decredAmountToString(amount: unconfirmed);
}
