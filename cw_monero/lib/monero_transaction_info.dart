import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/parseBoolFromString.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_monero/api/transaction_history.dart';

class MoneroTransactionInfo extends TransactionInfo {
  MoneroTransactionInfo(this.txHash, this.height, this.direction, this.date,
      this.isPending, this.amount, this.accountIndex, this.addressIndex, this.fee,
      this.confirmations) :
      id = "${txHash}_${amount}_${accountIndex}_${addressIndex}";

  MoneroTransactionInfo.fromMap(Map<String, Object?> map)
      : id = "${map['hash']}_${map['amount']}_${map['accountIndex']}_${map['addressIndex']}",
        txHash = map['hash'] as String,
        height = (map['height'] ?? 0) as int,
        direction = map['direction'] != null
            ? parseTransactionDirectionFromNumber(map['direction'] as String)
            : TransactionDirection.incoming,
        date = DateTime.fromMillisecondsSinceEpoch(
            (int.tryParse(map['timestamp'] as String? ?? '') ?? 0) * 1000),
        isPending = parseBoolFromString(map['isPending'] as String),
        amount = map['amount'] as int,
        accountIndex = int.parse(map['accountIndex'] as String),
        addressIndex = map['addressIndex'] as int,
        confirmations = map['confirmations'] as int,
        key = getTxKey((map['hash'] ?? '') as String),
        fee = map['fee'] as int? ?? 0 {
          additionalInfo = <String, dynamic>{
            'key': key,
            'accountIndex': accountIndex,
            'addressIndex': addressIndex
          };
        }

  final String id;
  final String txHash;
  final int height;
  final TransactionDirection direction;
  final DateTime date;
  final int accountIndex;
  final bool isPending;
  final int amount;
  final int fee;
  final int addressIndex;
  final int confirmations;
  String? recipientAddress;
  String? key;
  String? _fiatAmount;

  @override
  String amountFormatted() =>
      '${formatAmount(moneroAmountToString(amount: amount))} XMR';

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() =>
      '${formatAmount(moneroAmountToString(amount: fee))} XMR';
}
