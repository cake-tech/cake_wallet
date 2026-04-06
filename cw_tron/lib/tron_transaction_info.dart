import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:on_chain/tron/tron.dart';

class TronTransactionInfo extends TransactionInfo {
  TronTransactionInfo({
    required this.id,
    required this.amount,
    required this.txFee,
    required this.direction,
    required this.blockTime,
    required this.to,
    required this.from,
    required this.isPending,
    this.tokenSymbol = 'TRX',
  });

  @override
  final String id;
  @override
  final String? to;
  @override
  final String? from;
  @override
  final Money amount;
  @override
  final bool isPending;
  @override
  final TransactionDirection direction;

  final String tokenSymbol;
  final DateTime blockTime;
  final int? txFee;


  factory TronTransactionInfo.fromJson(Map<String, dynamic> data) {
    return TronTransactionInfo(
      id: data['id'] as String,
      amount: Money(BigInt.parse(data['tronAmount']), CryptoCurrency.trx),
      txFee: data['txFee'],
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      blockTime: DateTime.fromMillisecondsSinceEpoch(data['blockTime'] as int),
      tokenSymbol: data['tokenSymbol'] as String,
      to: data['to'],
      from: data['from'],
      isPending: data['isPending'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tronAmount': amount.amount.toString(),
        'txFee': txFee,
        'direction': direction.index,
        'blockTime': blockTime.millisecondsSinceEpoch,
        'tokenSymbol': tokenSymbol,
        'to': to,
        'from': from,
        'isPending': isPending,
      };

  @override
  DateTime get date => blockTime;

  String _rawAmountAsString(BigInt amount) {
    String formattedAmount = TronHelper.fromSun(amount);

    if (formattedAmount.length >= 8) {
      formattedAmount = formattedAmount.substring(0, 8);
    }

    return formattedAmount;
  }

  String rawTronAmount() => _rawAmountAsString(amount.amount);
}
