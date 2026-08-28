import 'package:cw_core/spl_token.dart';
import 'package:collection/collection.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/json_transaction_info.dart';

class SolanaTransactionInfo extends JsonTransactionInfo {
  SolanaTransactionInfo({
    required super.id,
    required super.date,
    required super.to,
    required super.from,
    required super.direction,
    required super.amount,
    required this.isPending,
    required Money super.fee,
  });

  @override
  String get txHash => id.replaceFirst(RegExp(r'_(outgoing|incoming)$'), '');

  @override
  final bool isPending;

  static CryptoCurrency amountCurrencyFor({
    required Iterable<SPLToken> tokens,
    required String tokenSymbol,
    required int decimals,
  }) {
    if (tokenSymbol == CryptoCurrency.sol.symbol) {
      return CryptoCurrency.sol;
    }

    return tokens.firstWhereOrNull(
          (token) => token.symbol.toLowerCase() == tokenSymbol.toLowerCase(),
        ) ??
        CryptoCurrency(name: tokenSymbol, title: tokenSymbol, decimals: decimals);
  }

  factory SolanaTransactionInfo.fromJson(
    Map<String, dynamic> data, {
    Iterable<SPLToken> tokens = const [],
  }) {
    final symbol = data['tokenSymbol'] as String? ?? "SOL";
    final decimals = data['tokenDecimals'] as int? ?? 6;

    final currency =
        amountCurrencyFor(tokens: tokens, tokenSymbol: symbol, decimals: decimals);

    return SolanaTransactionInfo(
      id: data['id'] as String,
      amount: Money.parse(data['solAmount'].toString(), currency),
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      date: DateTime.fromMillisecondsSinceEpoch(data['blockTime'] as int),
      isPending: data['isPending'] as bool,
      to: data['to'],
      from: data['from'],
      fee: Money.parse(data['txFee'], CryptoCurrency.sol),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'solAmount': amount.toString(),
        'direction': direction.index,
        'blockTime': date.millisecondsSinceEpoch,
        'isPending': isPending,
        'tokenSymbol': amount.currency.symbol,
        'tokenDecimals': amount.currency.decimals,
        'to': to,
        'from': from,
        'txFee': fee.toString(),
      };
}
