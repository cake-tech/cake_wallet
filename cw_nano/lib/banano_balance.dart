import 'package:cw_core/balance.dart';
import 'package:nanoutil/nanoutil.dart';

class BananoBalance extends Balance {
  final BigInt currentBalance;
  final BigInt receivableBalance;

  BananoBalance({required this.currentBalance, required this.receivableBalance}) : super(0, 0);

  @override
  String get formattedAvailableBalance {
    return NanoAmounts.getRawAsUsableString(currentBalance.toString(), NanoAmounts.rawPerBanano);
  }

  @override
  String get formattedAdditionalBalance {
    return NanoAmounts.getRawAsUsableString(receivableBalance.toString(), NanoAmounts.rawPerBanano);
  }
}
