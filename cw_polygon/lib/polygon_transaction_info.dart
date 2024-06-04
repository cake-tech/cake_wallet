import 'package:cw_core/transaction_direction.dart';
import 'package:cw_evm/evm_chain_transaction_info.dart';

class PolygonTransactionInfo extends EVMChainTransactionInfo {
  PolygonTransactionInfo({
    required super.id,
    required super.height,
    required super.ethAmount,
    required super.ethFee,
    required super.tokenSymbol,
    required super.direction,
    required super.isPending,
    required super.date,
    required super.confirmations,
    required super.to,
    required super.from,
    super.exponent,
  });

  factory PolygonTransactionInfo.fromJson(Map<String, dynamic> data) {
    return PolygonTransactionInfo(
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
      from: data['from'],
    );
  }

  @override
  String get feeCurrency => 'MATIC';
}
