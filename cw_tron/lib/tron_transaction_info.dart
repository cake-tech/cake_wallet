import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:on_chain/tron/tron.dart';

class TronTransactionInfo extends TransactionInfo {
  TronTransactionInfo({
    required this.id,
    required this.amount,
    required this.fee,
    required this.direction,
    required this.blockTime,
    required this.to,
    required this.from,
    required this.isPending,
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
  final Money? fee;

  @override
  final bool isPending;

  @override
  final TransactionDirection direction;

  final DateTime blockTime;

  factory TronTransactionInfo.fromJson(Map<String, dynamic> data) {
    final tokenSymbol = data['tokenSymbol'] as String;
    final decimals = data['decimals'] as int? ?? CryptoCurrency.trx.decimals;
    final currency = CryptoCurrency(name: tokenSymbol, title: tokenSymbol, decimals: decimals);

    return TronTransactionInfo(
      id: data['id'] as String,
      amount: Money(BigInt.parse(data['tronAmount']), currency),
      fee: Money.tryParse(data['txFee']?.toString() ?? '0', CryptoCurrency.trx, isBaseUnit: true),
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      blockTime: DateTime.fromMillisecondsSinceEpoch(data['blockTime'] as int),
      to: data['to'],
      from: data['from'],
      isPending: data['isPending'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tronAmount': amount.amount.toString(),
        'txFee': fee?.amount.toString(),
        'direction': direction.index,
        'blockTime': blockTime.millisecondsSinceEpoch,
        'to': to,
        'from': from,
        'isPending': isPending,
        'tokenSymbol': amount.currency.symbol,
        'decimals': amount.currency.decimals
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
