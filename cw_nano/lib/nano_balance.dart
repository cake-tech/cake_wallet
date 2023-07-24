import 'package:cw_core/balance.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/monero_amount_format.dart';

String rawToFormattedAmount(BigInt amount, Currency currency) {
  return "";
}

class NanoBalance extends Balance {
  final BigInt currentBalance;
  final BigInt receivableBalance;
  late String formattedCurrentBalance;
  late String formattedReceivableBalance;

  NanoBalance({required this.currentBalance, required this.receivableBalance}) : super(currentBalance.toInt(), receivableBalance.toInt()) {
    this.formattedCurrentBalance = "";
    this.formattedReceivableBalance = "";
  }

  // NanoBalance.fromString(
  //     {required this.formattedCurrentBalance, required this.formattedReceivableBalance})
  //     : currentBalance = moneroParseAmount(amount: formattedCurrentBalance),
  //       receivableBalance = moneroParseAmount(amount: formattedReceivableBalance),
  //       super(moneroParseAmount(amount: formattedReceivableBalance),
  //           moneroParseAmount(amount: formattedCurrentBalance));
}
