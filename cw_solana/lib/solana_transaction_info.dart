import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class SolanaTransactionInfo extends TransactionInfo {
  SolanaTransactionInfo({
    required this.id,
    required this.blockTime,
    required this.to,
    required this.direction,
    required this.solAmount,
    this.tokenSymbol = "SOL",
    required this.isPending,
  }) : amount = solAmount.toInt();

  final String id;
  final String? to;
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
  String feeFormatted() => '';

  factory SolanaTransactionInfo.fromJson(Map<String, dynamic> data) {
    return SolanaTransactionInfo(
      id: data['id'] as String,
      solAmount: data['amount'],
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      blockTime: DateTime.fromMillisecondsSinceEpoch(data['blockTime'] as int),
      isPending: data['isPending'] as bool,
      tokenSymbol: data['tokenSymbol'] as String,
      to: data['to'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': solAmount.toString(),
        'direction': direction.index,
        'blockTime': blockTime.millisecondsSinceEpoch,
        'isPending': isPending,
        'tokenSymbol': tokenSymbol,
        'to': to,
      };
}
