import 'dart:async';
import 'package:cake_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'anonpay_transactions_store.g.dart';

class AnonpayTransactionsStore = AnonpayTransactionsStoreBase with _$AnonpayTransactionsStore;

abstract class AnonpayTransactionsStoreBase with Store {
  AnonpayTransactionsStoreBase({
    required this.anonpayInvoiceInfoSource,
  }) : transactions = <AnonpayInvoiceInfo>[] {
    anonpayInvoiceInfoSource.watch().listen(
          (_) async => await updateTransactionList(),
        );
    updateTransactionList();
  }

  Box<AnonpayInvoiceInfo> anonpayInvoiceInfoSource;

  @observable
  List<AnonpayInvoiceInfo> transactions;

  @action
  Future<void> updateTransactionList() async {
    transactions = anonpayInvoiceInfoSource.values.toList();
  }
}
