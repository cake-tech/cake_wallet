import 'package:cw_core/balance.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_nano/nano_util.dart';

String rawToFormattedAmount(BigInt amount, Currency currency) {
  return "";
}

BigInt stringAmountToBigInt(String amount) {
  return BigInt.zero;
}

class BananoBalance extends Balance {
  final BigInt currentBalance;
  final BigInt receivableBalance;
  late String formattedCurrentBalance;
  late String formattedReceivableBalance;

  BananoBalance({required this.currentBalance, required this.receivableBalance}) : super(0, 0) {
    this.formattedCurrentBalance = "";
    this.formattedReceivableBalance = "";
  }

  BananoBalance.fromString(
      {required this.formattedCurrentBalance, required this.formattedReceivableBalance})
      : currentBalance = stringAmountToBigInt(formattedCurrentBalance),
        receivableBalance = stringAmountToBigInt(formattedReceivableBalance),
        super(0, 0);

  @override
  String get formattedAvailableBalance {
    return NanoUtil.getRawAsUsableString(currentBalance.toString(), NanoUtil.rawPerBanano);
  }

  @override
  String get formattedAdditionalBalance {
    return NanoUtil.getRawAsUsableString(receivableBalance.toString(), NanoUtil.rawPerBanano);
  }
}
