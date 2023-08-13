import 'package:cw_core/balance.dart';

class BitcoinCashBalance extends Balance {
  BitcoinCashBalance(this.balance) : super(balance, balance);

  final int balance;

  @override
  String get formattedAdditionalBalance => balance.toString();

  @override
  String get formattedAvailableBalance => balance.toString();
}
