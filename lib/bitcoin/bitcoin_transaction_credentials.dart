import 'package:cake_wallet/entities/transaction_priority.dart';

class BitcoinTransactionCredentials {
  BitcoinTransactionCredentials(this.address, this.amount, this.priority);

  final String address;
  final double amount;
  TransactionPriority priority;
}
