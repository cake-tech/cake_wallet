import 'package:cw_decred/amount_format.dart';
import 'package:cw_core/balance.dart';

class DecredBalance extends Balance {
  DecredBalance({required this.confirmed, required this.unconfirmed, required int frozen})
      : _frozen = frozen, super.fromInt(confirmed, unconfirmed);

  factory DecredBalance.zero() => DecredBalance(confirmed: 0, unconfirmed: 0, frozen: 0);

  final int confirmed;
  final int unconfirmed;
  final int _frozen;
  BigInt get frozen => BigInt.from(_frozen);

  @override
  String get formattedAvailableBalance => decredAmountToString(amount: confirmed - _frozen);

  @override
  String get formattedAdditionalBalance => decredAmountToString(amount: unconfirmed);

  @override
  String get formattedUnAvailableBalance {
    final frozenFormatted = decredAmountToString(amount: _frozen);
    return frozenFormatted == '0.0' ? '' : frozenFormatted;
  }
}
