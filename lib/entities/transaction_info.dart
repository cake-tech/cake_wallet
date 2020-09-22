import 'package:cake_wallet/entities/transaction_direction.dart';
import 'package:cake_wallet/utils/mobx.dart';

abstract class TransactionInfo extends Object with Keyable {
  String id;
  int amount;
  TransactionDirection direction;
  bool isPending;
  DateTime date;
  int height;
  int confirmations;
  String amountFormatted();
  String fiatAmount();
  void changeFiatAmount(String amount);

  @override
  dynamic get keyIndex => id;
}