import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_ethereum/ethereum_transaction_credentials.dart';
import 'package:cw_polygon/polygon_transaction_priority.dart';

class PolygonTransactionCredentials extends EthereumTransactionCredentials {
  PolygonTransactionCredentials(
    List<OutputInfo> outputs, {
    required PolygonTransactionPriority? priority,
    required CryptoCurrency currency,
    final int? feeRate,
  }) : super(
          outputs,
          currency: currency,
          priority: priority,
          feeRate: feeRate,
        );
}
