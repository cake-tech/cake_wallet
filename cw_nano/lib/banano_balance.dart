import 'package:cw_core/balance.dart';
import 'package:cw_nano/nano_util.dart';

class BananoBalance extends Balance {
  final BigInt currentBalance;
  final BigInt receivableBalance;

  BananoBalance({required this.currentBalance, required this.receivableBalance}) : super(0, 0) {
  }

  @override
  String get formattedAvailableBalance {
    return NanoUtil.getRawAsUsableString(currentBalance.toString(), NanoUtil.rawPerBanano);
  }

  @override
  String get formattedAdditionalBalance {
    return NanoUtil.getRawAsUsableString(receivableBalance.toString(), NanoUtil.rawPerBanano);
  }
}
