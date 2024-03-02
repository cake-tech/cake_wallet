import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class TronTransactionInfo extends TransactionInfo {
  TronTransactionInfo({
    required this.id,
    required this.tronAmount,
    required this.txFee,
    required this.direction,
    required this.isPending,
    required this.txDate,
    required this.to,
    required this.from,
    this.tokenSymbol = 'TRX',
  }) : amount = tronAmount.toInt();

  final String id;
  final String? to;
  final String? from;
  final int amount;
  final bool isPending;
  final BigInt tronAmount;
  final String tokenSymbol;
  final DateTime txDate;
  final BigInt txFee;
  final TransactionDirection direction;

  factory TronTransactionInfo.fromJson(Map<String, dynamic> data) {
    return TronTransactionInfo(
      id: data['id'] as String,
      tronAmount: BigInt.parse(data['amount']),
      txFee: BigInt.parse(data['fee']),
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      txDate: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      isPending: data['isPending'] as bool,
      tokenSymbol: data['tokenSymbol'] as String,
      to: data['to'],
      from: data['from'],
    );
  }

  @override
  DateTime get date => txDate;

  String? _fiatAmount;

  @override
  String amountFormatted() {
    String stringBalance = tronAmount.toString();

    if (stringBalance.toString().length >= 6) {
      stringBalance = stringBalance.substring(0, 6);
    }
    return '$stringBalance $tokenSymbol';
  }

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() => '${txFee.toString()} TRX';
}
