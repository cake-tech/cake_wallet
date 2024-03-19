import 'package:cw_core/balance.dart';
import 'package:cw_zano/zano_formatter.dart';

class ZanoBalance extends Balance {
  final int total;
  final int unlocked;
  final int decimalPoint;
  ZanoBalance({required this.total, required this.unlocked, required this.decimalPoint}) : super(unlocked, total - unlocked);

  @override
  String get formattedAdditionalBalance => ZanoFormatter.intAmountToString(total - unlocked, decimalPoint);

  @override
  String get formattedAvailableBalance => ZanoFormatter.intAmountToString(unlocked, decimalPoint);

  // @override
  // String get formattedFrozenBalance => '';
}
