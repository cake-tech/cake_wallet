import 'package:cw_core/balance.dart';
import 'package:nanoutil/nanoutil.dart';

BigInt stringAmountToBigInt(String amount) {
  return BigInt.parse(NanoAmounts.getAmountAsRaw(amount, NanoAmounts.rawPerNano));
}

class NanoBalance extends Balance {
  final BigInt currentBalance;
  final BigInt receivableBalance;

  NanoBalance({required this.currentBalance, required this.receivableBalance}) : super(0, 0);

  NanoBalance.fromString(
      {required String formattedCurrentBalance, required String formattedReceivableBalance})
      : currentBalance = stringAmountToBigInt(formattedCurrentBalance),
        receivableBalance = stringAmountToBigInt(formattedReceivableBalance),
        super(0, 0);

  @override
  String get formattedAvailableBalance {
    print("1");
    print(currentBalance.toString());
    print(NanoAmounts.getRawAsUsableString(currentBalance.toString(), NanoAmounts.rawPerNano));
    print("2");
    return NanoAmounts.getRawAsUsableString(currentBalance.toString(), NanoAmounts.rawPerNano);
  }

  @override
  String get formattedAdditionalBalance {
    return NanoAmounts.getRawAsUsableString(receivableBalance.toString(), NanoAmounts.rawPerNano);
  }
}
