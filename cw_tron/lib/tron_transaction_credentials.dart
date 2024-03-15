import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';

class TronTransactionCredentials {
  TronTransactionCredentials(
    this.outputs, {
    required this.currency,
  });

  final List<OutputInfo> outputs;
  final CryptoCurrency currency;
}
