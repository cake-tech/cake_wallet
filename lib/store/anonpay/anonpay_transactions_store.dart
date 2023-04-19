import 'dart:async';
import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:cake_wallet/view_model/dashboard/anonpay_transaction_list_item.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'anonpay_transactions_store.g.dart';

class AnonpayTransactionsStore = AnonpayTransactionsStoreBase with _$AnonpayTransactionsStore;

abstract class AnonpayTransactionsStoreBase with Store {
  AnonpayTransactionsStoreBase({
    required this.anonpayInvoiceInfoSource,
  }) : transactions = <AnonpayTransactionListItem>[] {
    anonpayInvoiceInfoSource.watch().listen(
          (_) async => await updateTransactionList(),
        );
    updateTransactionList();
  }

  Box<AnonpayInvoiceInfo> anonpayInvoiceInfoSource;

  @observable
  List<AnonpayTransactionListItem> transactions;

  @action
  Future<void> updateTransactionList() async {
    transactions = anonpayInvoiceInfoSource.values
        .map(
          (transaction) => AnonpayTransactionListItem(transaction: transaction),
        )
        .toList();
  }
}
