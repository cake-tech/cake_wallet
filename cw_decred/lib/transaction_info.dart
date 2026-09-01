import 'package:cw_core/amount/money.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class DecredTransactionInfo extends TransactionInfo {
  DecredTransactionInfo({
    required super.amount,
    required super.id,
    required Money super.fee,
    required super.direction,
    required bool isPending,
    required super.date,
    required int height,
    required int confirmations,
    required String super.to,
  }) {
    this.height = height;
    this.isPending = isPending;
    this.confirmations = confirmations;
  }
}
