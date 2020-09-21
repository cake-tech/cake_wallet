import 'package:cake_wallet/entities/transaction_direction.dart';

abstract class TransactionInfo extends Object {
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
}