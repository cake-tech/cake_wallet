import 'package:cw_core/transaction_direction.dart';
import 'package:cw_ethereum/ethereum_transaction_info.dart';

class PolygonTransactionInfo extends EthereumTransactionInfo {
  PolygonTransactionInfo({
    required String id,
    required int height,
    required BigInt ethAmount,
    int exponent = 18,
    required TransactionDirection direction,
    required DateTime date,
    required bool isPending,
    required BigInt ethFee,
    required int confirmations,
    String tokenSymbol = "MATIC",
    required String? to,
  }) : super(
          confirmations: confirmations,
          id: id,
          height: height,
          ethAmount: ethAmount,
          exponent: exponent,
          direction: direction,
          date: date,
          isPending: isPending,
          ethFee: ethFee,
          to: to,
          tokenSymbol: tokenSymbol,
        );

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
    );
  }

  @override
  String feeFormatted() => '${(ethFee / BigInt.from(10).pow(18)).toString()} MATIC';
}
