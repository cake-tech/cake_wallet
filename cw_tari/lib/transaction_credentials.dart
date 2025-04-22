import 'package:cw_core/output_info.dart';

class TariTransactionCredentials {
  TariTransactionCredentials(this.outputs, {this.feeRate});

  final List<OutputInfo> outputs;
  final int? feeRate;
}
