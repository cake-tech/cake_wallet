import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class SolanaTransactionInfo extends TransactionInfo {
  SolanaTransactionInfo({
    required this.id,
    required this.blockTime,
    required this.to,
    required this.from,
    required this.direction,
    required this.solAmount,
    this.tokenSymbol = "SOL",
    required this.isPending,
  }) : amount = solAmount.toInt();

  final String id;
  final String? to;
  final String? from;
  final int amount;
  final bool isPending;
  final double solAmount;
  final String tokenSymbol;
  final DateTime blockTime;
  final TransactionDirection direction;

  String? _fiatAmount;

  @override
  DateTime get date => blockTime;

  @override
  String amountFormatted() {
    String stringBalance = solAmount.toString();

    if (stringBalance.toString().length >= 6) {
      stringBalance = stringBalance.substring(0, 6);
    }
    return stringBalance;
  }

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() => throw UnimplementedError();

  factory SolanaTransactionInfo.fromJson(Map<String, dynamic> data) {
    return SolanaTransactionInfo(
      id: data['id'] as String,
      solAmount: data['solAmount'],
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      blockTime: DateTime.fromMillisecondsSinceEpoch(data['blockTime'] as int),
      isPending: data['isPending'] as bool,
      tokenSymbol: data['tokenSymbol'] as String,
      to: data['to'],
      from: data['from'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'solAmount': solAmount,
        'direction': direction.index,
        'blockTime': blockTime.millisecondsSinceEpoch,
        'isPending': isPending,
        'tokenSymbol': tokenSymbol,
        'to': to,
        'from': from,
      };
}
