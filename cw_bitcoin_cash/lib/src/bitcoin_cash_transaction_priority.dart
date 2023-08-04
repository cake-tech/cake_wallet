import 'package:cw_core/transaction_priority.dart';

class BitcoinCashTransactionPriority extends TransactionPriority{
  BitcoinCashTransactionPriority({required super.title, required super.raw});

  static BitcoinCashTransactionPriority deserialize ({required int raw}) {
    throw UnimplementedError('BitcoinCashTransactionPriority.deserialize() is not implemented');
  }
}