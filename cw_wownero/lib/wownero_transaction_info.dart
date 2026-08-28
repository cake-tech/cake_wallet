import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wownero_amount_format.dart';
import 'package:cw_core/parseBoolFromString.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_wownero/api/transaction_history.dart';

class WowneroTransactionInfo extends TransactionInfo {
  WowneroTransactionInfo(this.txHash, this.height, TransactionDirection direction, DateTime date,
      this.isPending, Money amount, this.accountIndex, this.addressIndex, Money fee,
      this.confirmations)
      : super(
          id: "${txHash}_${amount}_${accountIndex}_${addressIndex}",
          amount: amount,
          fee: fee,
          direction: direction,
          date: date,
        );

  WowneroTransactionInfo.fromMap(Map<String, Object?> map)
      : txHash = map['hash'] as String,
        height = (map['height'] ?? 0) as int,
        isPending = parseBoolFromString(map['isPending'] as String),
        accountIndex = int.parse(map['accountIndex'] as String),
        addressIndex = map['addressIndex'] as int,
        confirmations = map['confirmations'] as int,
        key = getTxKey((map['hash'] ?? '') as String),
        super(
          id: "${map['hash']}_${map['amount']}_${map['accountIndex']}_${map['addressIndex']}",
          amount: Money.fromInt(map['amount'] as int, CryptoCurrency.wow),
          fee: Money.fromInt(map['fee'] as int? ?? 0, CryptoCurrency.wow),
          direction: map['direction'] != null
              ? parseTransactionDirectionFromNumber(map['direction'] as String)
              : TransactionDirection.incoming,
          date: DateTime.fromMillisecondsSinceEpoch(
              (int.tryParse(map['timestamp'] as String? ?? '') ?? 0) * 1000),
        ) {
    additionalInfo = <String, dynamic>{
      'key': key,
      'accountIndex': accountIndex,
      'addressIndex': addressIndex
    };
  }

  final String txHash;
  final int height;
  final int accountIndex;
  final bool isPending;
  final int addressIndex;
  final int confirmations;
  String? recipientAddress;
  String? key;
  String? _fiatAmount;

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);
}
