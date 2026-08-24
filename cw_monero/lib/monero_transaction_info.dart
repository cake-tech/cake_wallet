import 'package:cw_core/amount/money.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class MoneroTransactionInfo extends TransactionInfo {
  MoneroTransactionInfo(this.txHash, this.height, this.direction, this.date, this.isPending,
      Money amount, this.accountIndex, this.addressIndex, this.fee, this.confirmations)
      : id = "${txHash}_${amount}_${accountIndex}_${addressIndex}",
        super(amount: amount);

  final String id;
  final String txHash;
  final int height;
  final TransactionDirection direction;
  final DateTime date;
  final int accountIndex;
  final bool isPending;
  final Money fee;
  final int addressIndex;
  final int confirmations;
  String? recipientAddress;
  String? key;

  @override
  int get neededConfirmations => 10;
}
