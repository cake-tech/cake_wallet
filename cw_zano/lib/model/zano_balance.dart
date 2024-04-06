import 'package:cw_core/balance.dart';
import 'package:cw_zano/zano_formatter.dart';

class ZanoBalance extends Balance {
  final int total;
  final int unlocked;
  final int decimalPoint;
  ZanoBalance({required this.total, required this.unlocked, this.decimalPoint = ZanoFormatter.defaultDecimalPoint}) : super(unlocked, total - unlocked);

  ZanoBalance.empty({this.decimalPoint = ZanoFormatter.defaultDecimalPoint}): total = 0, unlocked = 0, super(0, 0);

  @override
  String get formattedAdditionalBalance => ZanoFormatter.intAmountToString(total - unlocked, decimalPoint);

  @override
  String get formattedAvailableBalance => ZanoFormatter.intAmountToString(unlocked, decimalPoint);
}
