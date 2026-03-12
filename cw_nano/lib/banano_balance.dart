import 'package:cw_core/balance.dart';
import 'package:nanoutil/nanoutil.dart';

BigInt stringAmountToBigIntBanano(String amount) {
  return BigInt.parse(NanoAmounts.getAmountAsRaw(amount, NanoAmounts.rawPerBanano));
}

class BananoBalance extends Balance {
  final BigInt currentBalance;
  final BigInt receivableBalance;

  BananoBalance({required this.currentBalance, required this.receivableBalance}) : super(BigInt.zero, BigInt.zero);

  BananoBalance.fromFormattedString(
      {required String formattedCurrentBalance, required String formattedReceivableBalance})
      : currentBalance = stringAmountToBigIntBanano(formattedCurrentBalance),
        receivableBalance = stringAmountToBigIntBanano(formattedReceivableBalance),
        super(BigInt.zero, BigInt.zero);

  BananoBalance.fromRawString(
      {required String currentBalance, required String receivableBalance})
      : currentBalance = BigInt.parse(currentBalance),
        receivableBalance = BigInt.parse(receivableBalance),
        super(BigInt.zero, BigInt.zero);

  @override
  String get formattedAvailableBalance {
    return NanoAmounts.getRawAsUsableString(currentBalance.toString(), NanoAmounts.rawPerBanano);
  }

  @override
  String get formattedAdditionalBalance {
    return NanoAmounts.getRawAsUsableString(receivableBalance.toString(), NanoAmounts.rawPerBanano);
  }
}
