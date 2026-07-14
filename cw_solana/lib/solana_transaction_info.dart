import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class SolanaTransactionInfo extends TransactionInfo {
  SolanaTransactionInfo({
    required this.id,
    required this.date,
    required this.to,
    required this.from,
    required this.direction,
    required this.amount,
    required this.isPending,
    required this.fee,
  });

  @override
  final String id;
  @override
  final String? to;
  @override
  final String? from;

  @override
  String get txHash => id.replaceFirst(RegExp(r'_(outgoing|incoming)$'), '');

  @override
  final Money amount;
  @override
  final bool isPending;
  @override
  final Money fee;
  @override
  final TransactionDirection direction;
  @override
  final DateTime date;

  factory SolanaTransactionInfo.fromJson(Map<String, dynamic> data) {
    final symbol = data['tokenSymbol'] as String? ?? "SOL";
    final decimals = data['tokenDecimals'] as int? ?? 6;

    final currency = CryptoCurrency(name: symbol, title: symbol, decimals: decimals);

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
