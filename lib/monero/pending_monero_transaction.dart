import 'package:cw_monero/structs/pending_transaction.dart';
import 'package:cw_monero/transaction_history.dart'
    as monero_transaction_history;
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/core/amount_converter.dart';
import 'package:cake_wallet/core/pending_transaction.dart';

class PendingMoneroTransaction with PendingTransaction {
  PendingMoneroTransaction(this.pendingTransactionDescription);

  final PendingTransactionDescription pendingTransactionDescription;

  @override
  String get amountFormatted => AmountConverter.amountIntToString(
      CryptoCurrency.xmr, pendingTransactionDescription.amount);

  @override
  String get feeFormatted => AmountConverter.amountIntToString(
      CryptoCurrency.xmr, pendingTransactionDescription.fee);

  @override
  Future<void> commit() async =>
      monero_transaction_history.commitTransactionFromPointerAddress(
          address: pendingTransactionDescription.pointerAddress);
}
