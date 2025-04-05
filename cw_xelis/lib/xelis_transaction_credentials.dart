import 'package:cw_core/output_info.dart';
import 'package:cw_core/crypto_currency.dart';

import 'package:cw_xelis/xelis_transaction_priority.dart';

class XelisTransactionCredentials {
  XelisTransactionCredentials(this.outputs, {required this.priority, required this.currency});

  final List<OutputInfo> outputs;
  final XelisTransactionPriority? priority;
  final CryptoCurrency currency;
}
