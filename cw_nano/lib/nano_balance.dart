import 'package:cw_core/balance.dart';
import 'package:cw_nano/nano_util.dart';

BigInt stringAmountToBigInt(String amount) {
  return BigInt.parse(NanoUtil.getAmountAsRaw(amount, NanoUtil.rawPerNano));
}

class NanoBalance extends Balance {
  final BigInt currentBalance;
  final BigInt receivableBalance;
  late String formattedCurrentBalance;
  late String formattedReceivableBalance;

  NanoBalance({required this.currentBalance, required this.receivableBalance}) : super(0, 0) {
    this.formattedCurrentBalance = "";
    this.formattedReceivableBalance = "";
  }

  NanoBalance.fromString(
      {required this.formattedCurrentBalance, required this.formattedReceivableBalance})
      : currentBalance = stringAmountToBigInt(formattedCurrentBalance),
        receivableBalance = stringAmountToBigInt(formattedReceivableBalance),
        super(0, 0);

  @override
  String get formattedAvailableBalance {
    return NanoUtil.getRawAsUsableString(currentBalance.toString(), NanoUtil.rawPerNano);
  }

  @override
  String get formattedAdditionalBalance {
    return NanoUtil.getRawAsUsableString(receivableBalance.toString(), NanoUtil.rawPerNano);
  }
}
