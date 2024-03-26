import 'package:cw_core/balance.dart';
import 'package:nanoutil/nanoutil.dart';

BigInt stringAmountToBigIntBanano(String amount) {
  return BigInt.parse(NanoAmounts.getAmountAsRaw(amount, NanoAmounts.rawPerBanano));
}

class NanoBalance extends Balance {
  final BigInt currentBalance;
  final BigInt receivableBalance;

  NanoBalance({required this.currentBalance, required this.receivableBalance}) : super(0, 0);

  NanoBalance.fromFormattedString(
      {required String formattedCurrentBalance, required String formattedReceivableBalance})
      : currentBalance = stringAmountToBigIntBanano(formattedCurrentBalance),
        receivableBalance = stringAmountToBigIntBanano(formattedReceivableBalance),
        super(0, 0);

  NanoBalance.fromRawString(
      {required String currentBalance, required String receivableBalance})
      : currentBalance = BigInt.parse(currentBalance),
        receivableBalance = BigInt.parse(receivableBalance),
        super(0, 0);

  @override
  String get formattedAvailableBalance {
    return NanoAmounts.getRawAsUsableString(currentBalance.toString(), NanoAmounts.rawPerBanano);
  }

  @override
  String get formattedAdditionalBalance {
    return NanoAmounts.getRawAsUsableString(receivableBalance.toString(), NanoAmounts.rawPerBanano);
  }
}
