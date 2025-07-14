import 'dart:async';

import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/api/structs/pending_transaction.dart';
import 'package:cw_monero/api/transaction_history.dart'
    as monero_transaction_history;
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/amount_converter.dart';

import 'package:cw_core/pending_transaction.dart';
import 'package:cw_monero/api/wallet.dart';
import 'package:cw_monero/monero_wallet.dart';

class DoubleSpendException implements Exception {
  DoubleSpendException();

  @override
  String toString() =>
      'This transaction cannot be committed. This can be due to many reasons including the wallet not being synced, there is not enough XMR in your available balance, or previous transactions are not yet fully processed.';
}

class PendingMoneroTransaction with PendingTransaction {
  PendingMoneroTransaction(this.pendingTransactionDescription, this.wallet);

  final PendingTransactionDescription pendingTransactionDescription;
  final MoneroWalletBase wallet;

  @override
  String get id => pendingTransactionDescription.hash;

  @override
  String get hex => pendingTransactionDescription.hex;

  @override
  String get amountFormatted => AmountConverter.amountIntToString(
      CryptoCurrency.xmr, pendingTransactionDescription.amount);

  @override
  String get feeFormatted => "$feeFormattedValue XMR";

  @override
  String get feeFormattedValue => AmountConverter.amountIntToString(
      CryptoCurrency.xmr, pendingTransactionDescription.fee);

  bool shouldCommitUR() => isViewOnly;

  @override
  Future<void> commit() async {
    try {
      await monero_transaction_history.commitTransactionFromPointerAddress(
          address: pendingTransactionDescription.pointerAddress,
          useUR: false);
    } catch (e) {
      final message = e.toString();

      if (message.contains('Reason: double spend')) {
        throw DoubleSpendException();
      }

      rethrow;
    }
    storeSync(force: true);
    unawaited(() async {
      await Future.delayed(const Duration(milliseconds: 250));
      await wallet.fetchTransactions();
    }());
  }

  @override
  Future<String?> commitUR() async {
    try {
      final ret = await monero_transaction_history.commitTransactionFromPointerAddress(
          address: pendingTransactionDescription.pointerAddress,
          useUR: true);
      storeSync(force: true);
      unawaited(() async {
        await Future.delayed(const Duration(milliseconds: 250));
        await wallet.fetchTransactions();
      }());
      return ret;
    } catch (e) {
      final message = e.toString();

      if (message.contains('Reason: double spend')) {
        throw DoubleSpendException();
      }

      rethrow;
    }
  }
}
