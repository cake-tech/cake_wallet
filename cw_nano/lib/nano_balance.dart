import 'package:cw_core/balance.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/monero_amount_format.dart';

String rawToFormattedAmount(BigInt amount, Currency currency) {
  return "";
}

BigInt stringAmountToBigInt(String amount) {
  return BigInt.zero;
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
    return "0";
  }

  @override
  String get formattedAdditionalBalance {
    return "0";
  }
}
