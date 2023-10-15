import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';

import 'dummy_balance.dart';
import 'dummy_transaction_history.dart';
import 'dummy_transaction_info.dart';
import 'dummy_wallet_addresses.dart';

part 'dummy_wallet.g.dart';

class DummyWallet = DummyWalletBase with _$DummyWallet;

abstract class DummyWalletBase extends WalletBase<DummyBalance,
    DummyTransactionHistory, DummyTransactionInfo> with Store {
  DummyWalletBase({required WalletInfo walletInfo}) : super(walletInfo) {}

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) => throw UnimplementedError();

  @override
  Future<void> changePassword(String password) async => throw UnimplementedError();

  @override
  Future<void> close() async => throw UnimplementedError();

  @override
  Future<void> connectToNode({required Node node}) async => throw UnimplementedError();

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async => throw UnimplementedError();

  @override
  Future<Map<String, DummyTransactionInfo>> fetchTransactions() async => throw UnimplementedError();

  @override
  Future<void> renameWalletFiles(String newWalletName) async => throw UnimplementedError();

  @override
  Future<void> rescan({required int height}) async => throw UnimplementedError();

  @override
  Future<void> save() async => throw UnimplementedError();

  @override
  Future<void> startSync() async => throw UnimplementedError();

  @override
  Future<void>? updateBalance() => null;

  @override
  @observable
  late ObservableMap<CryptoCurrency, DummyBalance> balance;

  @override
  Object get keys => throw UnimplementedError("keys");

  @override
  String get seed => "seed";

  @override
  @observable
  late SyncStatus syncStatus;

  @override
  late DummyWalletAddresses walletAddresses;
}
