import 'dart:async';
import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:cake_wallet/monero/monero_amount_format.dart';
import 'package:cake_wallet/monero/monero_transaction_creation_exception.dart';
import 'package:cake_wallet/monero/monero_transaction_info.dart';
import 'package:cake_wallet/monero/monero_wallet_addresses.dart';
import 'package:cake_wallet/monero/monero_wallet_utils.dart';
import 'package:cw_monero/structs/pending_transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_monero/transaction_history.dart'
    as monero_transaction_history;
import 'package:cw_monero/wallet.dart';
import 'package:cw_monero/wallet.dart' as monero_wallet;
import 'package:cw_monero/transaction_history.dart' as transaction_history;
import 'package:cw_monero/monero_output.dart';
import 'package:cake_wallet/monero/monero_transaction_creation_credentials.dart';
import 'package:cake_wallet/monero/pending_monero_transaction.dart';
import 'package:cake_wallet/monero/monero_wallet_keys.dart';
import 'package:cake_wallet/monero/monero_balance.dart';
import 'package:cake_wallet/monero/monero_transaction_history.dart';
import 'package:cake_wallet/monero/account.dart';
import 'package:cake_wallet/core/pending_transaction.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/sync_status.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/entities/monero_transaction_priority.dart';

part 'monero_wallet.g.dart';

const moneroBlockSize = 1000;

class MoneroWallet = MoneroWalletBase with _$MoneroWallet;

abstract class MoneroWalletBase extends WalletBase<MoneroBalance,
    MoneroTransactionHistory, MoneroTransactionInfo> with Store {
  MoneroWalletBase({WalletInfo walletInfo})
      : super(walletInfo) {
    transactionHistory = MoneroTransactionHistory();
    balance = MoneroBalance(
        fullBalance: monero_wallet.getFullBalance(accountIndex: 0),
        unlockedBalance: monero_wallet.getFullBalance(accountIndex: 0));
    _lastAutosaveTimestamp = 0;
    _lastSaveTimestamp = 0;
    _isSavingAfterSync = false;
    _isSavingAfterNewTransaction = false;
    _isTransactionUpdating = false;
    walletAddresses = MoneroWalletAddresses(walletInfo);
    _onAccountChangeReaction = reaction((_) => walletAddresses.account,
            (Account account) {
      balance = MoneroBalance(
          fullBalance: monero_wallet.getFullBalance(accountIndex: account.id),
          unlockedBalance:
              monero_wallet.getUnlockedBalance(accountIndex: account.id));
      walletAddresses.updateSubaddressList(accountIndex: account.id);
    });
  }

  static const int _autoAfterSyncSaveInterval = 60000;

  @override
  MoneroWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

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

  SyncListener _listener;
  ReactionDisposer _onAccountChangeReaction;
  int _lastAutosaveTimestamp;
  bool _isSavingAfterSync;
  bool _isSavingAfterNewTransaction;
  bool _isTransactionUpdating;
  int _lastSaveTimestamp;

  Future<void> init() async {
    await walletAddresses.init();
    balance = MoneroBalance(
        fullBalance: monero_wallet.getFullBalance(accountIndex: walletAddresses.account.id),
        unlockedBalance:
            monero_wallet.getUnlockedBalance(accountIndex: walletAddresses.account.id));
    _setListeners();
    await updateTransactions();

    if (walletInfo.isRecovery) {
      monero_wallet.setRecoveringFromSeed(isRecovery: walletInfo.isRecovery);

      if (monero_wallet.getCurrentHeight() <= 1) {
        monero_wallet.setRefreshFromBlockHeight(
            height: walletInfo.restoreHeight);
      }
    }
  }

  @override
  void close() {
    _listener?.stop();
    _onAccountChangeReaction?.reaction?.dispose();
  }

  @override
  Future<void> connectToNode({@required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await monero_wallet.setupNode(
          address: node.uri.toString(),
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
    final outputs = _credentials.outputs;
    final hasMultiDestination = outputs.length > 1;
    final unlockedBalance =
    monero_wallet.getUnlockedBalance(accountIndex: walletAddresses.account.id);

    PendingTransactionDescription pendingTransactionDescription;

    if (!(syncStatus is SyncedSyncStatus)) {
      throw MoneroTransactionCreationException('The wallet is not synced.');
    }

    if (hasMultiDestination) {
      if (outputs.any((item) => item.sendAll
          || item.formattedCryptoAmount <= 0)) {
        throw MoneroTransactionCreationException('Wrong balance. Not enough XMR on your balance.');
      }

      final int totalAmount = outputs.fold(0, (acc, value) =>
          acc + value.formattedCryptoAmount);

      if (unlockedBalance < totalAmount) {
        throw MoneroTransactionCreationException('Wrong balance. Not enough XMR on your balance.');
      }

      final moneroOutputs = outputs.map((output) =>
          MoneroOutput(
              address: output.address,
              amount: output.cryptoAmount.replaceAll(',', '.')))
          .toList();

      pendingTransactionDescription =
      await transaction_history.createTransactionMultDest(
          outputs: moneroOutputs,
          priorityRaw: _credentials.priority.serialize(),
          accountIndex: walletAddresses.account.id);
    } else {
      final output = outputs.first;
      final address = output.address;
      final amount = output.sendAll
          ? null
          : output.cryptoAmount.replaceAll(',', '.');
      final formattedAmount = output.sendAll
          ? null
          : output.formattedCryptoAmount;

      if ((formattedAmount != null && unlockedBalance < formattedAmount) ||
          (formattedAmount == null && unlockedBalance <= 0)) {
        final formattedBalance = moneroAmountToString(amount: unlockedBalance);

        throw MoneroTransactionCreationException(
            'Incorrect unlocked balance. Unlocked: $formattedBalance. Transaction amount: ${output.cryptoAmount}.');
      }

      pendingTransactionDescription =
      await transaction_history.createTransaction(
          address: address,
          amount: amount,
          priorityRaw: _credentials.priority.serialize(),
          accountIndex: walletAddresses.account.id);
    }

    return PendingMoneroTransaction(pendingTransactionDescription);
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int amount) {
    // FIXME: hardcoded value;

    if (priority is MoneroTransactionPriority) {
      switch (priority) {
        case MoneroTransactionPriority.slow:
          return 24590000;
        case MoneroTransactionPriority.regular:
          return 123050000;
        case MoneroTransactionPriority.medium:
          return 245029999;
        case MoneroTransactionPriority.fast:
          return 614530000;
        case MoneroTransactionPriority.fastest:
          return 26021600000;
      }
    }

    return 0;
  }

  @override
  Future<void> save() async {
    await walletAddresses.updateAddressesInBox();

    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - _lastSaveTimestamp < Duration(seconds: 10).inMilliseconds) {
      return;
    }

    await backupWalletFiles(name);
    _lastSaveTimestamp = now;
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
    walletAddresses.accountList.update();
    await _askForUpdateTransactionHistory();
    await save();
    await walletInfo.save();
  }

  String getTransactionAddress(int accountIndex, int addressIndex) =>
      monero_wallet.getAddress(
          accountIndex: accountIndex,
          addressIndex: addressIndex);

  @override
  Future<Map<String, MoneroTransactionInfo>> fetchTransactions() async {
    monero_transaction_history.refreshTransactions();
    return _getAllTransactions(null).fold<Map<String, MoneroTransactionInfo>>(
        <String, MoneroTransactionInfo>{},
        (Map<String, MoneroTransactionInfo> acc, MoneroTransactionInfo tx) {
      acc[tx.id] = tx;
      return acc;
    });
  }

  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      _isTransactionUpdating = true;
      final transactions = await fetchTransactions();
      transactionHistory.addMany(transactions);
      await transactionHistory.save();
      _isTransactionUpdating = false;
    } catch (e) {
      print(e);
      _isTransactionUpdating = false;
    }
  }

  List<MoneroTransactionInfo> _getAllTransactions(dynamic _) =>
      monero_transaction_history
          .getAllTransations()
          .map((row) => MoneroTransactionInfo.fromRow(row))
          .toList();

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

  Future<void> _askForUpdateTransactionHistory() async =>
      await updateTransactions();

  int _getFullBalance() =>
      monero_wallet.getFullBalance(accountIndex: walletAddresses.account.id);

  int _getUnlockedBalance() =>
      monero_wallet.getUnlockedBalance(accountIndex: walletAddresses.account.id);

  Future<void> _afterSyncSave() async {
    try {
      if (_isSavingAfterSync) {
        return;
      }

      _isSavingAfterSync = true;

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
    try {
      if (_isSavingAfterNewTransaction) {
        return;
      }

      _isSavingAfterNewTransaction = true;

      await save();
    } catch (e) {
      print(e.toString());
    }

    _isSavingAfterNewTransaction = false;
  }

  void _onNewBlock(int height, int blocksLeft, double ptc) async {
    try {
      if (walletInfo.isRecovery) {
        await _askForUpdateTransactionHistory();
        _askForUpdateBalance();
        walletAddresses.accountList.update();
      }

      if (blocksLeft < 100) {
        await _askForUpdateTransactionHistory();
        _askForUpdateBalance();
        walletAddresses.accountList.update();
        syncStatus = SyncedSyncStatus();
        await _afterSyncSave();

        if (walletInfo.isRecovery) {
          await setAsRecovered();
        }
      } else {
        syncStatus = SyncingSyncStatus(blocksLeft, ptc);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _onNewTransaction() async {
    try {
      await _askForUpdateTransactionHistory();
      _askForUpdateBalance();
      await Future<void>.delayed(Duration(seconds: 1));
      await _afterNewTransactionSave();
    } catch (e) {
      print(e.toString());
    }
  }
}
