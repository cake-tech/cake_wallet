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
      subaddressList.update(accountIndex: account.id);
      subaddress = subaddressList.subaddresses.first;
      address = subaddress.address;
    });
  }

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
  SyncListner _listener;
  ReactionDisposer _onAccountChangeReaction;

  Future<void> init() async {
    await accountList.update();
    account = accountList.accounts.first;
    subaddressList.update(accountIndex: account.id ?? 0);
    subaddress = subaddressList.getAll().first;
    balance = MoneroBalance(
        fullBalance: monero_wallet.getFullBalance(accountIndex: account.id),
        unlockedBalance:
            monero_wallet.getFullBalance(accountIndex: account.id));
    address = subaddress.address;
    _setListeners();
    await transactionHistory.update();
  }

  void close() {
    _listener?.stop();
    _onAccountChangeReaction?.reaction?.dispose();
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
      _setInitialHeight();
    } catch (_) {}

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
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final _credentials = credentials as MoneroTransactionCreationCredentials;
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
    monero_wallet.rescanBlockchainAsync();
  }

  void _setListeners() {
    _listener?.stop();
    _listener = monero_wallet.setListeners(
        _onNewBlock, _onNeedToRefresh, _onNewTransaction);
    _listener.start();
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
    final fullBalance = _getFullBalance();
    final unlockedBalance = _getUnlockedBalance();

    if (balance.fullBalance != fullBalance ||
        balance.unlockedBalance != unlockedBalance) {
      balance = MoneroBalance(
          fullBalance: fullBalance, unlockedBalance: unlockedBalance);
    }
  }

  Future<void> _askForUpdateTransactionHistory() async {
    print('start');
    await transactionHistory.update();
    print('end');
  }

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

    if (walletInfo.isRecovery) {
      _askForUpdateTransactionHistory();
    }

    final currentHeight = getCurrentHeight();
    final nodeHeight = monero_wallet.getNodeHeightSync();

    if (walletInfo.isRecovery &&
        (nodeHeight - currentHeight < moneroBlockSize)) {
      await setAsRecovered();
    }

    await save();
  }

  void _onNewTransaction() {
    _askForUpdateBalance();
    _askForUpdateTransactionHistory();
  }
}
