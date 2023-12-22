import 'package:cw_decred/transaction_history.dart';
import 'package:cw_decred/wallet_addresses.dart';
import 'package:cw_decred/transaction_priority.dart';
import 'package:cw_decred/api/dcrlibwallet.dart';
import 'package:cw_decred/balance.dart';
import 'package:cw_decred/transaction_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:mobx/mobx.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/unspent_transaction_output.dart';

part 'wallet.g.dart';

class DecredWallet = DecredWalletBase with _$DecredWallet;

abstract class DecredWalletBase extends WalletBase<DecredBalance,
    DecredTransactionHistory, DecredTransactionInfo> with Store {
  DecredWalletBase(SPVWallet spv, WalletInfo walletInfo)
      : this.spv = spv,
        balance = ObservableMap<CryptoCurrency, DecredBalance>.of(
            {CryptoCurrency.dcr: spv.balance()}),
        syncStatus = NotConnectedSyncStatus(),
        super(walletInfo) {
    transactionHistory = DecredTransactionHistory();
    walletAddresses = DecredWalletAddresses(walletInfo, spv);
  }

  final SPVWallet spv;

  static Future<DecredWallet> create(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo}) async {
    final seed = mnemonicToSeedBytes(mnemonic);
    final spv = SPVWallet().create(seed, password, walletInfo);
    final wallet = DecredWallet(spv, walletInfo);
    return wallet;
  }

  static Future<DecredWallet> open(
      {required String password,
      required String name,
      required WalletInfo walletInfo}) async {
    final spv = SPVWallet().load(name, password, walletInfo);
    final wallet = DecredWallet(spv, walletInfo);
    return wallet;
  }

  // TODO: Set up a way to change the balance and sync status when dcrlibwallet
  // changes. Long polling probably?
  @override
  @observable
  late ObservableMap<CryptoCurrency, DecredBalance> balance;

  @override
  @observable
  SyncStatus syncStatus;

  // @override
  // set syncStatus(SyncStatus status);

  @override
  String? get seed {
    // throw UnimplementedError();
    return "";
  }

  // @override
  // String? get privateKey => null;

  @override
  Object get keys {
    // throw UnimplementedError();
    return {};
  }

  @override
  late DecredWalletAddresses walletAddresses;

  // @override
  // set isEnabledAutoGenerateSubaddress(bool value) {}

  // @override
  // bool get isEnabledAutoGenerateSubaddress => false;

  @override
  Future<void> connectToNode({required Node node}) async {
    //throw UnimplementedError();
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      this.spv.startSync();
      syncStatus = this.spv.syncStatus();
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    return this.spv.createTransaction(credentials);
  }

  int feeRate(TransactionPriority priority) {
    try {
      return this.spv.feeRate(priority.raw);
    } catch (_) {
      return 0;
    }
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    if (priority is DecredTransactionPriority) {
      return this.spv.calculateEstimatedFeeWithFeeRate(
          this.spv.feeRate(priority.raw), amount ?? 0);
    }

    return 0;
  }

  @override
  Future<Map<String, DecredTransactionInfo>> fetchTransactions() async {
    return this.spv.transactions();
  }

  @override
  Future<void> save() async {}

  @override
  Future<void> rescan({required int height}) async {
    return spv.rescan(height);
  }

  @override
  void close() {
    this.spv.close();
  }

  @override
  Future<void> changePassword(String password) async {
    return this.spv.changePassword(password);
  }

  @override
  String get password {
    // throw UnimplementedError();
    return "";
  }

  @override
  Future<void>? updateBalance() async {
    balance[CryptoCurrency.dcr] = this.spv.balance();
  }

  @override
  void setExceptionHandler(void Function(FlutterErrorDetails) onError) =>
      onError;

  Future<void> renameWalletFiles(String newWalletName) async {
    final currentWalletPath =
        await pathForWallet(name: walletInfo.name, type: type);
    final currentWalletFile = File(currentWalletPath);

    final currentDirPath =
        await pathForWalletDir(name: walletInfo.name, type: type);

    // TODO: Stop the wallet, wait, and restart after.

    // Copies current wallet files into new wallet name's dir and files
    if (currentWalletFile.existsSync()) {
      final newWalletPath =
          await pathForWallet(name: newWalletName, type: type);
      await currentWalletFile.copy(newWalletPath);
    }

    // Delete old name's dir and files
    await Directory(currentDirPath).delete(recursive: true);
  }

  @override
  String signMessage(String message, {String? address = null}) {
    return this.spv.signMessage(message, address);
  }

  List<Unspent> unspents() {
    return this.spv.unspents();
  }
}
