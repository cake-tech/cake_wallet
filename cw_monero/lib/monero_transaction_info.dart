import 'package:cw_core/amount/money.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class MoneroTransactionInfo extends TransactionInfo {
  MoneroTransactionInfo(this.txHash, this.height, TransactionDirection direction, DateTime date,
      this.isPending, Money amount, this.accountIndex, this.addressIndex, Money fee,
      this.confirmations)
      : super(
          id: "${txHash}_${amount}_${accountIndex}_${addressIndex}",
          amount: amount,
          fee: fee,
          direction: direction,
          date: date,
        );

  final String txHash;
  final int height;
  final int accountIndex;
  final bool isPending;
  final int addressIndex;
  final int confirmations;
  String? recipientAddress;
  String? key;

  @override
  int get neededConfirmations => 10;
}
