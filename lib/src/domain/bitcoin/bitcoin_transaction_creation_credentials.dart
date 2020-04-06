import 'package:cake_wallet/src/domain/common/transaction_creation_credentials.dart';

class BitcoinTransactionCreationCredentials
    extends TransactionCreationCredentials {
  BitcoinTransactionCreationCredentials({this.address, this.amount});

  final String address;
  final String amount;
}