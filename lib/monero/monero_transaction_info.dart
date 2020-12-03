import 'package:cake_wallet/entities/transaction_info.dart';
import 'package:cake_wallet/monero/monero_amount_format.dart';
import 'package:cw_monero/structs/transaction_info_row.dart';
import 'package:cake_wallet/entities/parseBoolFromString.dart';
import 'package:cake_wallet/entities/transaction_direction.dart';
import 'package:cake_wallet/entities/format_amount.dart';
import 'package:cw_monero/transaction_history.dart';

class MoneroTransactionInfo extends TransactionInfo {
  MoneroTransactionInfo(this.id, this.height, this.direction, this.date,
      this.isPending, this.amount, this.accountIndex, this.fee);

  MoneroTransactionInfo.fromMap(Map map)
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
        key = getTxKey((map['hash'] ?? '') as String),
        fee = map['fee'] as int ?? 0;

  MoneroTransactionInfo.fromRow(TransactionInfoRow row)
      : id = row.getHash(),
        height = row.blockHeight,
        direction = parseTransactionDirectionFromInt(row.direction) ??
            TransactionDirection.incoming,
        date = DateTime.fromMillisecondsSinceEpoch(row.getDatetime() * 1000),
        isPending = row.isPending != 0,
        amount = row.getAmount(),
        accountIndex = row.subaddrAccount,
        key = getTxKey(row.getHash()),
        fee = row.fee;

  final String id;
  final int height;
  final TransactionDirection direction;
  final DateTime date;
  final int accountIndex;
  final bool isPending;
  final int amount;
  final int fee;
  String recipientAddress;
  String key;

  String _fiatAmount;

  @override
  String amountFormatted() =>
      '${formatAmount(moneroAmountToString(amount: amount))} XMR';

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  String feeFormatted() =>
      '${formatAmount(moneroAmountToString(amount: fee))} XMR';
}
