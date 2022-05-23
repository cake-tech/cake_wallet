import 'package:cw_core/transaction_info.dart';
import 'package:cw_wownero/wownero_amount_format.dart';
import 'package:cw_wownero/api/structs/transaction_info_row.dart';
import 'package:cw_core/parseBoolFromString.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_wownero/api/transaction_history.dart';

class WowneroTransactionInfo extends TransactionInfo {
  WowneroTransactionInfo(this.id, this.height, this.direction, this.date,
      this.isPending, this.amount, this.accountIndex, this.addressIndex, this.fee);

  WowneroTransactionInfo.fromMap(Map map)
      : id = (map['hash'] ?? '') as String,
        height = (map['height'] ?? 0) as int,
        direction =
            parseTransactionDirectionFromNumber(map['direction'] as String) ??
                TransactionDirection.incoming,
        date = DateTime.fromMillisecondsSinceEpoch(
            (int.parse(map['timestamp'] as String) ?? 0) * 1000),
        isPending = parseBoolFromString(map['isPending'] as String),
        amount = map['amount'] as int,
        accountIndex = int.parse(map['accountIndex'] as String),
        addressIndex = map['addressIndex'] as int,
        key = getTxKey((map['hash'] ?? '') as String),
        fee = map['fee'] as int ?? 0 {
          additionalInfo = {
            'key': key,
            'accountIndex': accountIndex,
            'addressIndex': addressIndex
          };
        }

  WowneroTransactionInfo.fromRow(TransactionInfoRow row)
      : id = row.getHash(),
        height = row.blockHeight,
        direction = parseTransactionDirectionFromInt(row.direction) ??
            TransactionDirection.incoming,
        date = DateTime.fromMillisecondsSinceEpoch(row.getDatetime() * 1000),
        isPending = row.isPending != 0,
        amount = row.getAmount(),
        accountIndex = row.subaddrAccount,
        addressIndex = row.subaddrIndex,
        key = getTxKey(row.getHash()),
        fee = row.fee {
          additionalInfo = {
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
  String recipientAddress;
  String key;

  String _fiatAmount;

  @override
  String amountFormatted() =>
      '${formatAmount(wowneroAmountToString(amount: amount))} WOW';

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() =>
      '${formatAmount(wowneroAmountToString(amount: fee))} WOW';
}
