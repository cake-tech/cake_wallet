import 'package:cake_wallet/src/domain/monero/monero_amount_format.dart';
import 'package:cw_monero/structs/transaction_info_row.dart';
import 'package:cake_wallet/src/domain/common/parseBoolFromString.dart';
import 'package:cake_wallet/src/domain/common/transaction_direction.dart';
import 'package:cake_wallet/src/domain/common/format_amount.dart';

class TransactionInfo {
  TransactionInfo(this.id, this.height, this.direction, this.date,
      this.isPending, this.amount, this.accountIndex);

  TransactionInfo.fromMap(Map map)
      : id = (map['hash'] ?? '') as String,
        height = (map['height'] ?? 0) as int,
        direction =
            parseTransactionDirectionFromNumber(map['direction'] as String) ??
                TransactionDirection.incoming,
        date = DateTime.fromMillisecondsSinceEpoch(
            (int.parse(map['timestamp'] as String) ?? 0) * 1000),
        isPending = parseBoolFromString(map['isPending'] as String),
        amount = map['amount'] as int,
        accountIndex = int.parse(map['accountIndex'] as String);

  TransactionInfo.fromRow(TransactionInfoRow row)
      : id = row.getHash(),
        height = row.blockHeight,
        direction = parseTransactionDirectionFromInt(row.direction) ??
            TransactionDirection.incoming,
        date = DateTime.fromMillisecondsSinceEpoch(row.getDatetime() * 1000),
        isPending = row.isPending != 0,
        amount = row.getAmount(),
        accountIndex = row.subaddrAccount;

  final String id;
  final int height;
  final TransactionDirection direction;
  final DateTime date;
  final int accountIndex;
  final bool isPending;
  final int amount;
  String recipientAddress;

  String _fiatAmount;

  String amountFormatted() => '${formatAmount(moneroAmountToString(amount: amount))} XMR';

  String fiatAmount() => _fiatAmount ?? '';

  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);
}
