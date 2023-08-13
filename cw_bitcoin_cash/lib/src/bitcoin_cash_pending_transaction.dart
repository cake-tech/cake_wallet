import 'package:cw_core/pending_transaction.dart';

class BitcoinCashPendingTransaction with PendingTransaction {
  @override
  // TODO: implement amountFormatted
  String get amountFormatted => throw UnimplementedError('amountFormatted is not implemented');

  @override
  Future<void> commit() {
    // TODO: implement commit
    throw UnimplementedError('commit is not implemented');
  }

  @override
  // TODO: implement feeFormatted
  String get feeFormatted => throw UnimplementedError('feeFormatted is not implemented');

  @override
  // TODO: implement hex
  String get hex => throw UnimplementedError('hex is not implemented');

  @override
  // TODO: implement id
  String get id => throw UnimplementedError('id is not implemented');
}
