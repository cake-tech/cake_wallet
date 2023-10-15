import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_dummy/dummy_transaction_info.dart';
import 'package:cw_dummy/dummy_transaction_priority.dart';
import 'package:cw_dummy/dummy_wallet.dart';
import 'package:cw_dummy/dummy_wallet_creation_credentials.dart';
import 'package:cw_dummy/dummy_transaction_creation_credentials.dart';
import 'package:cw_dummy/dummy_wallet_service.dart';
import 'package:hive/hive.dart';

part 'cw_dummy.dart';

Dummy? dummy = CWDummy();

abstract class Dummy {
  WalletCredentials createDummyNewWalletCredentials(
      {required String name, WalletInfo? walletInfo});
  WalletCredentials createDummyRestoreWalletFromKeyCredentials(
      {required String name, WalletInfo? walletInfo});
  WalletCredentials createDummyRestoreWalletFromSeedCredentials(
      {required String name, WalletInfo? walletInfo});
  WalletService createDummyWalletService(Box<WalletInfo> walletInfoSource);
  TransactionPriority deserializeDummyTransactionPriority(int raw);
  List<String> getDummyWordList();
  List<TransactionPriority> getTransactionPriorities();
  TransactionPriority getDefaultTransactionPriority();
  CryptoCurrency assetOfTransaction(TransactionInfo tx);
  double formatterDummyAmountToDouble({required int amount});
  TransactionPriority getDummyTransactionPrioritySlow();
  TransactionPriority getDummyTransactionPriorityMedium();
  int formatterDummyParseAmount({required String amount});
  Object createDummyTransactionCreationCredentials({required List<Output> outputs, required TransactionPriority priority});
  Future<void> generateNewAddress(Object wallet);
  String getAddress(WalletBase wallet);
}
