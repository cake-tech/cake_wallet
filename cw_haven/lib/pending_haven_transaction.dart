import 'package:cw_haven/api/structs/pending_transaction.dart';
import 'package:cw_haven/api/transaction_history.dart'
    as haven_transaction_history;
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/pending_transaction.dart';

class DoubleSpendException implements Exception {
  DoubleSpendException();

  @override
  String toString() =>
      'This transaction cannot be committed. This can be due to many reasons including the wallet not being synced, there is not enough XMR in your available balance, or previous transactions are not yet fully processed.';
}

class PendingHavenTransaction with PendingTransaction {
  PendingHavenTransaction(this.pendingTransactionDescription, this.cryptoCurrency);

  final PendingTransactionDescription pendingTransactionDescription;
  final CryptoCurrency cryptoCurrency;

  @override
  String get id => pendingTransactionDescription.hash;

  @override
  String get hex => '';

  @override
  String get amountFormatted => AmountConverter.amountIntToString(
      cryptoCurrency, pendingTransactionDescription.amount);

  @override
  String get feeFormatted => AmountConverter.amountIntToString(
      cryptoCurrency, pendingTransactionDescription.fee);

  @override
  Future<void> commit() async {
    try {
      haven_transaction_history.commitTransactionFromPointerAddress(
          address: pendingTransactionDescription.pointerAddress);
    } catch (e) {
      final message = e.toString();

      if (message.contains('Reason: double spend')) {
        throw DoubleSpendException();
      }

      rethrow;
    }
  }
}
