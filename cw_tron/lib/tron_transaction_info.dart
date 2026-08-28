import 'package:cw_core/tron_token.dart';
import 'package:collection/collection.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/json_transaction_info.dart';
import 'package:on_chain/tron/tron.dart';

class TronTransactionInfo extends JsonTransactionInfo {
  TronTransactionInfo({
    required super.id,
    required super.amount,
    required super.fee,
    required super.direction,
    required DateTime blockTime,
    required super.to,
    required super.from,
    required this.isPending,
  }) : super(date: blockTime);

  @override
  final bool isPending;

  static CryptoCurrency amountCurrencyFor({
    required Iterable<TronToken> tokens,
    required String tokenSymbol,
    required int decimals,
  }) {
    if (tokenSymbol == CryptoCurrency.trx.title) {
      return CryptoCurrency.trx;
    }

    return tokens.firstWhereOrNull(
          (token) => token.symbol.toLowerCase() == tokenSymbol.toLowerCase(),
        ) ??
        CryptoCurrency(name: tokenSymbol, title: tokenSymbol, decimals: decimals);
  }

  factory TronTransactionInfo.fromJson(
    Map<String, dynamic> data, {
    Iterable<TronToken> tokens = const [],
  }) {
    final tokenSymbol = data['tokenSymbol'] as String;
    final decimals = data['decimals'] as int? ?? CryptoCurrency.trx.decimals;
    final currency =
        amountCurrencyFor(tokens: tokens, tokenSymbol: tokenSymbol, decimals: decimals);

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

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'tronAmount': amount.amount.toString(),
        'txFee': fee?.amount.toString(),
        'direction': direction.index,
        'blockTime': date.millisecondsSinceEpoch,
        'to': to,
        'from': from,
        'isPending': isPending,
        'tokenSymbol': amount.currency.symbol,
        'decimals': amount.currency.decimals
      };


  String _rawAmountAsString(BigInt amount) {
    String formattedAmount = TronHelper.fromSun(amount);

    if (formattedAmount.length >= 8) {
      formattedAmount = formattedAmount.substring(0, 8);
    }

    return formattedAmount;
  }

  String rawTronAmount() => _rawAmountAsString(amount.amount);
}
