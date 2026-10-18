import 'package:cw_core/amount/money.dart';
import 'package:cw_wownero/api/structs/pending_transaction.dart';
import 'package:cw_wownero/api/transaction_history.dart' as wownero_transaction_history;
import 'package:cw_core/crypto_currency.dart';

import 'package:cw_core/pending_transaction.dart';

class DoubleSpendException implements Exception {
  DoubleSpendException();

  @override
  String toString() =>
      'This transaction cannot be committed. This can be due to many reasons including the wallet not being synced, there is not enough WOW in your available balance, or previous transactions are not yet fully processed.';
}

class PendingWowneroTransaction with PendingTransaction {
  PendingWowneroTransaction(this.pendingTransactionDescription);

  final PendingTransactionDescription pendingTransactionDescription;

  Money get amount => Money.fromInt(pendingTransactionDescription.amount, CryptoCurrency.wow);

  Money get fee => Money.fromInt(pendingTransactionDescription.fee, CryptoCurrency.wow);

  @override
  String get id => pendingTransactionDescription.hash;

  @override
  String get hex => pendingTransactionDescription.hex;

  String get txKey => pendingTransactionDescription.txKey;

  @override
  String get amountFormatted => amount.toString();

  @override
  Future<void> commit() async {
    try {
      wownero_transaction_history.commitTransactionFromPointerAddress(
          address: pendingTransactionDescription.pointerAddress);
    } catch (e) {
      final message = e.toString();

      if (message.contains('Reason: double spend')) {
        throw DoubleSpendException();
      }

      rethrow;
    }
  }

  @override
  Future<Map<String, String>> commitUR() {
    throw UnimplementedError();
  }
}
