import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/monero/monero_balance.dart';
import 'package:cake_wallet/monero/monero_transaction_history.dart';
import 'package:cake_wallet/monero/monero_subaddress_list.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/core/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/monero/account.dart';
import 'package:cake_wallet/src/domain/monero/account_list.dart';
import 'package:cake_wallet/src/domain/monero/subaddress.dart';
import 'package:cw_monero/wallet.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cw_monero/wallet.dart' as monero_wallet;

part 'monero_wallet.g.dart';

class MoneroWallet = MoneroWalletBase with _$MoneroWallet;

abstract class MoneroWalletBase extends WalletBase<MoneroBalance> with Store {
  MoneroWalletBase({String filename, this.isRecovery = false})
      : transactionHistory = MoneroTransactionHistory() {
    _filename = filename;
    accountList = AccountList();
    subaddressList = MoneroSubaddressList();
    balance = MoneroBalance(
        fullBalance: monero_wallet.getFullBalance(accountIndex: 0),
        unlockedBalance: monero_wallet.getFullBalance(accountIndex: 0));
  }

  @override
  final MoneroTransactionHistory transactionHistory;

  @observable
  Account account;

  @observable
  Subaddress subaddress;

  @observable
  SyncStatus syncStatus;

  @override
  String get name => _filename.split('/').last;

  @override
  final type = WalletType.monero;

  @override
  @observable
  String address;

  bool isRecovery;

  MoneroSubaddressList subaddressList;

  AccountList accountList;

  String _filename;

  SyncListner _listener;

  Future<void> init() async {
    await accountList.update();
    account = accountList.getAll().first;
    subaddressList.update(accountIndex: account.id ?? 0);
    subaddress = subaddressList.getAll().first;
    balance = MoneroBalance(
        fullBalance: monero_wallet.getFullBalance(accountIndex: account.id),
        unlockedBalance:
            monero_wallet.getFullBalance(accountIndex: account.id));
    address = subaddress.address;
    _setListeners();
  }

  void close() {
    _listener?.stop();
  }

  @override
  Future<void> connectToNode({@required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await monero_wallet.setupNode(
          address: node.uri,
          login: node.login,
          password: node.password,
          useSSL: false,
          // FIXME: hardcoded value
          isLightWallet: false); // FIXME: hardcoded value
      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print(e);
    }
  }

  @override
  Future<void> startSync() async {
    try {
      syncStatus = StartingSyncStatus();
      monero_wallet.startRefresh();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print(e);
      rethrow;
    }
  }

  @override
  Future<void> createTransaction(Object credentials) async {
//    final _credentials = credentials as MoneroTransactionCreationCredentials;
//    final transactionDescription = await transaction_history.createTransaction(
//        address: _credentials.address,
//        paymentId: _credentials.paymentId,
//        amount: _credentials.amount,
//        priorityRaw: _credentials.priority.serialize(),
//        accountIndex: _account.value.id);
//
//    return PendingTransaction.fromTransactionDescription(
//        transactionDescription);
  }

  @override
  Future<void> save() async {
//    if (_isSaving) {
//      return;
//    }

    try {
//      _isSaving = true;
      await monero_wallet.store();
//      _isSaving = false;
    } catch (e) {
      print(e);
//      _isSaving = false;
      rethrow;
    }
  }

  Future<int> getNodeHeight() async => monero_wallet.getNodeHeight();

  Future<bool> isConnected() async => monero_wallet.isConnected();

  void _setListeners() {
    _listener?.stop();
    _listener = monero_wallet.setListeners(
        _onNewBlock, _onNeedToRefresh, _onNewTransaction);
  }

  void _askForUpdateBalance() {
    final fullBalance = _getFullBalance();
    final unlockedBalance = _getUnlockedBalance();

    if (balance.fullBalance != fullBalance ||
        balance.unlockedBalance != unlockedBalance) {
      balance = MoneroBalance(
          fullBalance: fullBalance, unlockedBalance: unlockedBalance);
    }
  }

  void _askForUpdateTransactionHistory() =>
      null; // await getHistory().update();

  int _getFullBalance() =>
      monero_wallet.getFullBalance(accountIndex: account.id);

  int _getUnlockedBalance() =>
      monero_wallet.getUnlockedBalance(accountIndex: account.id);

  void _onNewBlock(int height, int blocksLeft, double ptc) =>
      syncStatus = SyncingSyncStatus(blocksLeft, ptc);

  Future _onNeedToRefresh() async {
    if (syncStatus is FailedSyncStatus) {
      return;
    }

    syncStatus = SyncedSyncStatus();

    if (isRecovery) {
      _askForUpdateTransactionHistory();
    }

//      if (isRecovery && (nodeHeight - currentHeight < moneroBlockSize)) {
//        await setAsRecovered();
//      }

    await save();
  }

  void _onNewTransaction() {
    _askForUpdateBalance();
    _askForUpdateTransactionHistory();
  }
}
