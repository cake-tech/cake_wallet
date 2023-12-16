import 'package:cw_core/balance.dart';
import 'package:cw_core/monero_amount_format.dart';

class ZanoBalance extends Balance {
  final int total;
  final int unlocked;
  ZanoBalance({required this.total, required this.unlocked}): super(unlocked, total-unlocked);

  @override
  String get formattedAdditionalBalance => moneroAmountToString(amount: total-unlocked);

  @override
  String get formattedAvailableBalance => moneroAmountToString(amount: unlocked);

  @override
  String get formattedFrozenBalance => '';

}
