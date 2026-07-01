import 'package:cw_core/amount/money.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class DecredTransactionInfo extends TransactionInfo {
  DecredTransactionInfo({
    required String id,
    required Money amount,
    required Money fee,
    required TransactionDirection direction,
    required bool isPending,
    required DateTime date,
    required int height,
    required int confirmations,
    required String to,
  }) {
    this.id = id;
    this.amount = amount;
    this.fee = fee;
    this.height = height;
    this.direction = direction;
    this.date = date;
    this.isPending = isPending;
    this.confirmations = confirmations;
    this.to = to;
  }
}
