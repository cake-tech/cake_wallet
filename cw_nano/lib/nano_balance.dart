import 'package:cw_core/balance.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:nanoutil/nanoutil.dart';

BigInt stringAmountToBigIntNano(String amount) {
  return BigInt.parse(NanoAmounts.getAmountAsRaw(amount, NanoAmounts.rawPerNano));
}

class NanoBalance extends Balance {
  final BigInt currentBalance;
  final BigInt receivableBalance;

  NanoBalance({required this.currentBalance, required this.receivableBalance}) : super(currentBalance, receivableBalance);

  NanoBalance.fromFormattedString(
      {required String formattedCurrentBalance, required String formattedReceivableBalance})
      : currentBalance = stringAmountToBigIntNano(formattedCurrentBalance),
        receivableBalance = stringAmountToBigIntNano(formattedReceivableBalance),
        super(stringAmountToBigIntNano(formattedCurrentBalance), stringAmountToBigIntNano(formattedReceivableBalance));

  NanoBalance.fromRawString(
      {required String currentBalance, required String receivableBalance})
      : currentBalance = BigInt.parse(currentBalance),
        receivableBalance = BigInt.parse(receivableBalance),
        super(BigInt.parse(currentBalance), BigInt.parse(receivableBalance));

  @override
  String get formattedAvailableBalance {
    return NanoAmounts.getRawAsUsableString(currentBalance.toString(), NanoAmounts.rawPerNano);
  }

  @override
  String get formattedAdditionalBalance {
    return NanoAmounts.getRawAsUsableString(receivableBalance.toString(), NanoAmounts.rawPerNano);
  }
}
