import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:on_chain/on_chain.dart' as onchain;
import 'package:on_chain/tron/tron.dart';

class TronTransactionInfo extends TransactionInfo {
  TronTransactionInfo({
    required this.id,
    required this.tronAmount,
    required this.txFee,
    required this.direction,
    required this.blockTime,
    required this.to,
    required this.from,
    required this.isPending,
    this.tokenSymbol = 'TRX',
  }) : amount = tronAmount.toInt();

  final String id;
  final String? to;
  final String? from;
  final int amount;
  final BigInt tronAmount;
  final String tokenSymbol;
  final DateTime blockTime;
  final bool isPending;
  final int? txFee;
  final TransactionDirection direction;

  factory TronTransactionInfo.fromJson(Map<String, dynamic> data) {
    return TronTransactionInfo(
      id: data['id'] as String,
      tronAmount: BigInt.parse(data['tronAmount']),
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
        'tronAmount': tronAmount.toString(),
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

  String? _fiatAmount;

  @override
  String amountFormatted() {
    String formattedAmount = _rawAmountAsString(tronAmount);

    return '$formattedAmount $tokenSymbol';
  }

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  @override
  String feeFormatted() {
    final formattedFee = onchain.TronHelper.fromSun(BigInt.from(txFee ?? 0));

    return '$formattedFee TRX';
  }

  String _rawAmountAsString(BigInt amount) {
    String formattedAmount = TronHelper.fromSun(amount);

    if (formattedAmount.length >= 8) {
      formattedAmount = formattedAmount.substring(0, 8);
    }

    return formattedAmount;
  }

  String rawTronAmount() => _rawAmountAsString(tronAmount);
}
