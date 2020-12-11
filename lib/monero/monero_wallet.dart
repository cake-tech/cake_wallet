import 'dart:async';

import 'package:cake_wallet/monero/monero_amount_format.dart';
import 'package:cake_wallet/monero/monero_transaction_creation_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_monero/wallet.dart';
import 'package:cw_monero/wallet.dart' as monero_wallet;
import 'package:cw_monero/transaction_history.dart' as transaction_history;
import 'package:cake_wallet/monero/monero_transaction_creation_credentials.dart';
import 'package:cake_wallet/monero/pending_monero_transaction.dart';
import 'package:cake_wallet/monero/monero_wallet_keys.dart';
import 'package:cake_wallet/monero/monero_balance.dart';
import 'package:cake_wallet/monero/monero_transaction_history.dart';
import 'package:cake_wallet/monero/monero_subaddress_list.dart';
import 'package:cake_wallet/monero/monero_account_list.dart';
import 'package:cake_wallet/monero/account.dart';
import 'package:cake_wallet/monero/subaddress.dart';
import 'package:cake_wallet/core/pending_transaction.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/sync_status.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/entities/transaction_priority.dart';

part 'monero_wallet.g.dart';

const moneroBlockSize = 1000;

class MoneroWallet = MoneroWalletBase with _$MoneroWallet;

abstract class MoneroWalletBase extends WalletBase<MoneroBalance> with Store {
  MoneroWalletBase({String filename, WalletInfo walletInfo})
      : transactionHistory = MoneroTransactionHistory(),
        accountList = MoneroAccountList(),
        subaddressList = MoneroSubaddressList(),
        super(walletInfo) {
    _filename = filename;
    balance = MoneroBalance(
        fullBalance: monero_wallet.getFullBalance(accountIndex: 0),
        unlockedBalance: monero_wallet.getFullBalance(accountIndex: 0));
    _onAccountChangeReaction = reaction((_) => account, (Account account) {
      balance = MoneroBalance(
          fullBalance: monero_wallet.getFullBalance(accountIndex: account.id),
          unlockedBalance:
          monero_wallet.getUnlockedBalance(accountIndex: account.id));
      subaddressList.update(accountIndex: account.id);
      subaddress = subaddressList.subaddresses.first;
      address = subaddress.address;
      _lastAutosaveTimestamp = 0;
      _isSavingAfterSync = false;
      _isSavingAfterNewTransaction = false;
    });
  }

  static const int _autoAfterSyncSaveInterval = 60000;

  @override
  final MoneroTransactionHistory transactionHistory;

  @observable
  Account account;

  @observable
  Subaddress subaddress;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  String address;

  @override
  @observable
  MoneroBalance balance;

  @override
  String get seed => monero_wallet.getSeed();

  @override
  MoneroWalletKeys get keys => MoneroWalletKeys(
      privateSpendKey: monero_wallet.getSecretSpendKey(),
      privateViewKey: monero_wallet.getSecretViewKey(),
      publicSpendKey: monero_wallet.getPublicSpendKey(),
      publicViewKey: monero_wallet.getPublicViewKey());

  final MoneroSubaddressList subaddressList;

  final MoneroAccountList accountList;

  String _filename;
  SyncListener _listener;
  ReactionDisposer _onAccountChangeReaction;
  int _lastAutosaveTimestamp;
  bool _isSavingAfterSync;
  bool _isSavingAfterNewTransaction;

  Future<void> init() async {
    accountList.update();
    account = accountList.accounts.first;
    subaddressList.update(accountIndex: account.id ?? 0);
    subaddress = subaddressList.getAll().first;
    balance = MoneroBalance(
        fullBalance: monero_wallet.getFullBalance(accountIndex: account.id),
        unlockedBalance:
            monero_wallet.getUnlockedBalance(accountIndex: account.id));
    address = subaddress.address;
    _setListeners();
    await transactionHistory.update();

    if (walletInfo.isRecovery) {
      monero_wallet.setRecoveringFromSeed(isRecovery: walletInfo.isRecovery);

      if (monero_wallet.getCurrentHeight() <= 1) {
        monero_wallet.setRefreshFromBlockHeight(
            height: walletInfo.restoreHeight);
      }
    }
  }

  void close() {
    _listener?.stop();
    _onAccountChangeReaction?.reaction?.dispose();
  }

  bool validate() {
    accountList.update();
    final accountListLength = accountList.accounts?.length ?? 0;

    if (accountListLength <= 0) {
      return false;
    }

    subaddressList.update(accountIndex: accountList.accounts.first.id);
    final subaddressListLength = subaddressList.subaddresses?.length ?? 0;

    if (subaddressListLength <= 0) {
      return false;
    }

    return true;
  }

  @override
  Future<void> connectToNode({@required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await monero_wallet.setupNode(
          address: node.uri,
          login: node.login,
          password: node.password,
          useSSL: node.isSSL,
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
      _setInitialHeight();
    } catch (_) {}

    try {
      syncStatus = StartingSyncStatus();
      monero_wallet.startRefresh();
      _setListeners();
      _listener?.start();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print(e);
      rethrow;
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final _credentials = credentials as MoneroTransactionCreationCredentials;
    final amount = _credentials.amount != null
        ? moneroParseAmount(amount: _credentials.amount)
        : null;
    final unlockedBalance =
        monero_wallet.getUnlockedBalance(accountIndex: account.id);

    if ((amount != null && unlockedBalance < amount) ||
        (amount == null && unlockedBalance <= 0)) {
      final formattedBalance = moneroAmountToString(amount: unlockedBalance);

      throw MoneroTransactionCreationException(
          'Incorrect unlocked balance. Unlocked: $formattedBalance. Transaction amount: ${_credentials.amount}.');
    }

    if (!(syncStatus is SyncedSyncStatus)) {
      throw MoneroTransactionCreationException('The wallet is not synced.');
    }

    final pendingTransactionDescription =
        await transaction_history.createTransaction(
            address: _credentials.address,
            paymentId: _credentials.paymentId,
            amount: _credentials.amount,
            priorityRaw: _credentials.priority.serialize(),
            accountIndex: account.id);

    return PendingMoneroTransaction(pendingTransactionDescription);
  }

  @override
  double calculateEstimatedFee(TransactionPriority priority) {
    // FIXME: hardcoded value;

    if (priority == TransactionPriority.slow) {
      return 0.00002459;
    }

    if (priority == TransactionPriority.regular) {
      return 0.00012305;
    }

    if (priority == TransactionPriority.medium) {
      return 0.00024503;
    }

    if (priority == TransactionPriority.fast) {
      return 0.00061453;
    }

    if (priority == TransactionPriority.fastest) {
      return 0.0260216;
    }

    return 0;
  }

  @override
  Future<void> save() async {
    await monero_wallet.store();
  }

  Future<int> getNodeHeight() async => monero_wallet.getNodeHeight();

  Future<bool> isConnected() async => monero_wallet.isConnected();

  Future<void> setAsRecovered() async {
    walletInfo.isRecovery = false;
    await walletInfo.save();
  }

  @override
  Future<void> rescan({int height}) async {
    walletInfo.restoreHeight = height;
    walletInfo.isRecovery = true;
    monero_wallet.setRefreshFromBlockHeight(height: height);
    monero_wallet.rescanBlockchainAsync();
    await startSync();
    _askForUpdateBalance();
    accountList.update();
    await _askForUpdateTransactionHistory();
    await save();
    await walletInfo.save();
  }

  void _setListeners() {
    _listener?.stop();
    _listener = monero_wallet.setListeners(_onNewBlock, _onNewTransaction);
  }

  void _setInitialHeight() {
    if (walletInfo.isRecovery) {
      return;
    }

    final currentHeight = getCurrentHeight();

    if (currentHeight <= 1) {
      final height = _getHeightByDate(walletInfo.date);
      monero_wallet.setRecoveringFromSeed(isRecovery: true);
      monero_wallet.setRefreshFromBlockHeight(height: height);
    }
  }

  int _getHeightDistance(DateTime date) {
    final distance =
        DateTime.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch;
    final daysTmp = (distance / 86400).round();
    final days = daysTmp < 1 ? 1 : daysTmp;

    return days * 1000;
  }

  int _getHeightByDate(DateTime date) {
    final nodeHeight = monero_wallet.getNodeHeightSync();
    final heightDistance = _getHeightDistance(date);

    if (nodeHeight <= 0) {
      return 0;
    }

    return nodeHeight - heightDistance;
  }

  void _askForUpdateBalance() {
    final unlockedBalance = _getUnlockedBalance();
    final fullBalance = _getFullBalance();

    if (balance.fullBalance != fullBalance ||
        balance.unlockedBalance != unlockedBalance) {
      balance = MoneroBalance(
          fullBalance: fullBalance, unlockedBalance: unlockedBalance);
    }
  }

  Future<void> _askForUpdateTransactionHistory() async {
    await transactionHistory.update();
  }

  int _getFullBalance() =>
      monero_wallet.getFullBalance(accountIndex: account.id);

  int _getUnlockedBalance() =>
      monero_wallet.getUnlockedBalance(accountIndex: account.id);

  Future<void> _afterSyncSave() async {
    if (_isSavingAfterSync) {
      return;
    }

    _isSavingAfterSync = true;

    try {
      final nowTimestamp = DateTime.now().millisecondsSinceEpoch;
      final sum = _lastAutosaveTimestamp + _autoAfterSyncSaveInterval;

      if (_lastAutosaveTimestamp > 0 && sum < nowTimestamp) {
        return;
      }

      await save();
      _lastAutosaveTimestamp = nowTimestamp + _autoAfterSyncSaveInterval;
    } catch (e) {
      print(e.toString());
    }

    _isSavingAfterSync = false;
  }

  Future<void> _afterNewTransactionSave() async {
    if (_isSavingAfterNewTransaction) {
      return;
    }

    _isSavingAfterNewTransaction = true;

    try {
      await save();
    } catch (e) {
      print(e.toString());
    }

    _isSavingAfterNewTransaction = false;
  }

  void _onNewBlock(int height, int blocksLeft, double ptc) async {
    if (walletInfo.isRecovery) {
      await _askForUpdateTransactionHistory();
      _askForUpdateBalance();
      accountList.update();
    }

    if (blocksLeft < 100) {
      await _askForUpdateTransactionHistory();
      _askForUpdateBalance();
      accountList.update();
      syncStatus = SyncedSyncStatus();
      await _afterSyncSave();

      if (walletInfo.isRecovery) {
        await setAsRecovered();
      }
    } else {
      syncStatus = SyncingSyncStatus(blocksLeft, ptc);
    }
  }

  void _onNewTransaction() {
    _askForUpdateTransactionHistory();
    _askForUpdateBalance();
    Timer(Duration(seconds: 1), () => _afterNewTransactionSave());
  }
}
