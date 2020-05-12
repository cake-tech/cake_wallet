import 'package:cake_wallet/src/domain/common/transaction_direction.dart';

abstract class TransactionInfo extends Object {
  int amount;
  TransactionDirection direction;
  bool isPending;
  DateTime date;
  int height;
  String amountFormatted();
  String fiatAmount();
}