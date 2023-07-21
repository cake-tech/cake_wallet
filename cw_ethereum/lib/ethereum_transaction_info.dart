import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class EthereumTransactionInfo extends TransactionInfo {
  EthereumTransactionInfo({
    required this.id,
    required this.height,
    required this.amount,
    required this.fee,
    this.tokenSymbol = "ETH",
    this.exponent = 18,
    required this.direction,
    required this.isPending,
    required this.date,
    required this.confirmations,
  });

  final String id;
  final int height;
  final int amount;
  final int exponent;
  final TransactionDirection direction;
  final DateTime date;
  final bool isPending;
  final int fee;
  final int confirmations;
  final String tokenSymbol;
  String? _fiatAmount;

  @override
  String amountFormatted() =>
      '${formatAmount((BigInt.from(amount) / BigInt.from(10).pow(exponent)).toString())} $tokenSymbol';

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() => '${(BigInt.from(fee) / BigInt.from(10).pow(exponent)).toString()} ETH';

  factory EthereumTransactionInfo.fromJson(Map<String, dynamic> data) {
    return EthereumTransactionInfo(
        id: data['id'] as String,
        height: data['height'] as int,
        amount: data['amount'] as int,
        fee: data['fee'] as int,
        direction: parseTransactionDirectionFromInt(data['direction'] as int),
        date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
        isPending: data['isPending'] as bool,
        confirmations: data['confirmations'] as int);
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    m['id'] = id;
    m['height'] = height;
    m['amount'] = amount;
    m['direction'] = direction.index;
    m['date'] = date.millisecondsSinceEpoch;
    m['isPending'] = isPending;
    m['confirmations'] = confirmations;
    m['fee'] = fee;
    return m;
  }
}
