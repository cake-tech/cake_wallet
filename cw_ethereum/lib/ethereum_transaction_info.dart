import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';

class EthereumTransactionInfo extends TransactionInfo {
  EthereumTransactionInfo({
    required this.id,
    required this.height,
    required this.ethAmount,
    required this.ethFee,
    this.tokenSymbol = "ETH",
    this.exponent = 18,
    required this.direction,
    required this.isPending,
    required this.date,
    required this.confirmations,
    required this.to,
  })  : this.amount = ethAmount.toInt(),
        this.fee = ethFee.toInt();

  final String id;
  final int height;
  final int amount;
  final BigInt ethAmount;
  final int exponent;
  final TransactionDirection direction;
  final DateTime date;
  final bool isPending;
  final int fee;
  final BigInt ethFee;
  final int confirmations;
  final String tokenSymbol;
  String? _fiatAmount;
  final String? to;

  @override
  String amountFormatted() =>
      '${formatAmount((ethAmount / BigInt.from(10).pow(exponent)).toString())} $tokenSymbol';

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() => '${(ethFee / BigInt.from(10).pow(18)).toString()} ETH';

  factory EthereumTransactionInfo.fromJson(Map<String, dynamic> data) {
    return EthereumTransactionInfo(
      id: data['id'] as String,
      height: data['height'] as int,
      ethAmount: BigInt.parse(data['amount']),
      exponent: data['exponent'] as int,
      ethFee: BigInt.parse(data['fee']),
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      isPending: data['isPending'] as bool,
      confirmations: data['confirmations'] as int,
      tokenSymbol: data['tokenSymbol'] as String,
      to: data['to'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'height': height,
        'amount': ethAmount.toString(),
        'exponent': exponent,
        'fee': ethFee.toString(),
        'direction': direction.index,
        'date': date.millisecondsSinceEpoch,
        'isPending': isPending,
        'confirmations': confirmations,
        'tokenSymbol': tokenSymbol,
        'to': to,
      };
}
