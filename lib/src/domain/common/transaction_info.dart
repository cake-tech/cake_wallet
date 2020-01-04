import 'package:cake_wallet/src/domain/monero/monero_amount_format.dart';
import 'package:cw_monero/structs/transaction_info_row.dart';
import 'package:cake_wallet/src/domain/common/parseBoolFromString.dart';
import 'package:cake_wallet/src/domain/common/transaction_direction.dart';

class TransactionInfo {
  final String id;
  final int height;
  final TransactionDirection direction;
  final DateTime date;
  final int accountIndex;
  final bool isPending;
  final int amount;
  String recipientAddress;
  String _fiatAmount;

  TransactionInfo.fromMap(Map map)
      : id = map['hash'] ?? '',
        height = map['height'] ?? '',
        direction = parseTransactionDirectionFromNumber(map['direction']) ??
            TransactionDirection.incoming,
        date = DateTime.fromMillisecondsSinceEpoch(
            (int.parse(map['timestamp']) ?? 0) * 1000),
        isPending = parseBoolFromString(map['isPending']),
        amount = map['amount'],
        accountIndex = int.parse(map['accountIndex']);

  TransactionInfo.fromRow(TransactionInfoRow row)
      : id = row.getHash(),
        height = row.blockHeight,
        direction = parseTransactionDirectionFromInt(row.direction) ??
            TransactionDirection.incoming,
        date = DateTime.fromMillisecondsSinceEpoch(row.getDatetime() * 1000),
        isPending = row.isPending != 0,
        amount = row.getAmount(),
        accountIndex = row.subaddrAccount;

  TransactionInfo(this.id, this.height, this.direction, this.date,
      this.isPending, this.amount, this.accountIndex);

  String amountFormatted() => '${moneroAmountToString(amount: amount)} XMR';

  String fiatAmount() => _fiatAmount ?? '';

  changeFiatAmount(String amount) => _fiatAmount = amount;
}
