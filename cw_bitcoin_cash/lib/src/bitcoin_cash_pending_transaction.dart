
import 'package:cw_core/pending_transaction.dart';

class BitcoinCashPendingTransaction with PendingTransaction {
  @override
  // TODO: implement amountFormatted
  String get amountFormatted => throw UnimplementedError();

  @override
  Future<void> commit() {
    // TODO: implement commit
    throw UnimplementedError();
  }

  @override
  // TODO: implement feeFormatted
  String get feeFormatted => throw UnimplementedError();

  @override
  // TODO: implement hex
  String get hex => throw UnimplementedError();

  @override
  // TODO: implement id
  String get id => throw UnimplementedError();
}
