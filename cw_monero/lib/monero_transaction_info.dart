import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_monero/api/structs/transaction_info_row.dart';
import 'package:cw_core/parseBoolFromString.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_monero/api/transaction_history.dart';

class MoneroTransactionInfo extends TransactionInfo {
  MoneroTransactionInfo(this.id, this.height, this.direction, this.date,
      this.isPending, this.amount, this.accountIndex, this.addressIndex, this.fee, this.unlockTime);

  MoneroTransactionInfo.fromRow(TransactionInfoRow row)
      : id = row.getHash(),
        height = row.blockHeight,
        direction = TransactionDirection.parseFromInt(row.direction),
        date = DateTime.fromMillisecondsSinceEpoch(row.getDatetime() * 1000),
        isPending = row.isPending != 0,
        amount = row.getAmount(),
        accountIndex = row.subaddrAccount,
        addressIndex = row.subaddrIndex,
        unlockTime = row.unlockTime,
        key = getTxKey(row.getHash()),
        fee = row.fee {
          additionalInfo = <String, dynamic>{
            'key': key,
            'accountIndex': accountIndex,
            'addressIndex': addressIndex
          };
        }

  final String id;
  final int height;
  final TransactionDirection direction;
  final DateTime date;
  final int accountIndex;
  final bool isPending;
  final int amount;
  final int fee;
  final int addressIndex;
  final int unlockTime;
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

  @override
  String? unlockTimeFormatted() {
    final formattedTime = unlockTime * 2;
    if (direction == TransactionDirection.outgoing || unlockTime == 0) {
      return null;
    }

    if (formattedTime > 500000) {
      return '>1 year';
    }
    return '~ $formattedTime minutes';
  }
}
