import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cw_monero/wallet.dart' as moneroWallet;
import 'package:cw_monero/transaction_history.dart' as transactionHistory;
import 'package:cake_wallet/src/domain/common/wallet_info.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/common/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/transaction_creation_credentials.dart';
import 'package:cake_wallet/src/domain/common/pending_transaction.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/monero/monero_amount_format.dart';
import 'package:cake_wallet/src/domain/monero/account.dart';
import 'package:cake_wallet/src/domain/monero/account_list.dart';
import 'package:cake_wallet/src/domain/monero/subaddress_list.dart';
import 'package:cake_wallet/src/domain/monero/monero_transaction_creation_credentials.dart';
import 'package:cake_wallet/src/domain/monero/monero_transaction_history.dart';
import 'package:cake_wallet/src/domain/monero/subaddress.dart';
import 'package:cake_wallet/src/domain/common/balance.dart';
import 'package:cake_wallet/src/domain/monero/monero_balance.dart';

const monero_block_size = 1000;

class MoneroWallet extends Wallet {
  static Future<MoneroWallet> createdWallet(
      {Box<WalletInfo> walletInfoSource,
      String name,
      bool isRecovery = false,
      int restoreHeight = 0}) async {
    const type = WalletType.monero;
    final id = walletTypeToString(type).toLowerCase() + '_' + name;
    final walletInfo = WalletInfo(
        id: id,
        name: name,
        type: type,
        isRecovery: isRecovery,
        restoreHeight: restoreHeight);
    await walletInfoSource.add(walletInfo);

    return await configured(
        walletInfo: walletInfo, walletInfoSource: walletInfoSource);
  }

  static Future<MoneroWallet> load(
      Box<WalletInfo> walletInfoSource, String name, WalletType type) async {
    final id = walletTypeToString(type).toLowerCase() + '_' + name;
    final walletInfo =
        walletInfoSource.values.firstWhere((info) => info.id == id, orElse: () => null);
    return await configured(
        walletInfoSource: walletInfoSource, walletInfo: walletInfo);
  }

  static Future<MoneroWallet> configured(
      {@required Box<WalletInfo> walletInfoSource,
      @required WalletInfo walletInfo}) async {
    final wallet = MoneroWallet(
        walletInfoSource: walletInfoSource, walletInfo: walletInfo);

    if (walletInfo.isRecovery) {
      await wallet.setRecoveringFromSeed();

      if (walletInfo.restoreHeight != null) {
        await wallet.setRefreshFromBlockHeight(
            height: walletInfo.restoreHeight);
      }
    }

    return wallet;
  }

  WalletType getType() => WalletType.monero;
  bool get isRecovery => walletInfo.isRecovery;
  Observable<SyncStatus> get syncStatus => _syncStatus.stream;
  Observable<Balance> get onBalanceChange => _onBalanceChange.stream;
  Observable<Account> get onAccountChange => _account.stream;
  Observable<String> get onNameChange => _name.stream;
  Observable<String> get onAddressChange => _address.stream;
  Observable<Subaddress> get subaddress => _subaddress.stream;

  Account get account => _account.value;
  String get address => _address.value;
  String get name => _name.value;

  Box<WalletInfo> walletInfoSource;
  WalletInfo walletInfo;

  BehaviorSubject<Account> _account;
  BehaviorSubject<MoneroBalance> _onBalanceChange;
  BehaviorSubject<SyncStatus> _syncStatus;
  BehaviorSubject<String> _name;
  BehaviorSubject<String> _address;
  BehaviorSubject<Subaddress> _subaddress;
  int _cachedBlockchainHeight;
  bool _isSaving;
  int _lastSaveTime;
  int _lastRefreshTime;
  int _refreshHeight;
  int _lastSyncHeight;

  TransactionHistory _cachedTransactionHistory;
  SubaddressList _cachedSubaddressList;
  AccountList _cachedAccountList;

  MoneroWallet(
      {this.walletInfoSource, this.walletInfo}) {
    _cachedBlockchainHeight = 0;
    _isSaving = false;
    _lastSaveTime = 0;
    _lastRefreshTime = 0;
    _refreshHeight = 0;
    _lastSyncHeight = 0;
    _name = BehaviorSubject<String>();
    _address = BehaviorSubject<String>();
    _syncStatus = BehaviorSubject<SyncStatus>();
    _onBalanceChange = BehaviorSubject<MoneroBalance>();
    _account = BehaviorSubject<Account>()..add(Account(id: 0));
    _subaddress = BehaviorSubject<Subaddress>();
    setListeners();
  }

  Future updateInfo() async {
    _name.value = await getName();
    final acccountList = getAccountList();
    await acccountList.refresh();
    _account.value = acccountList.getAll().first;
    final subaddressList = getSubaddress();
    await subaddressList.refresh(
        accountIndex: _account.value != null ? _account.value.id : 0);
    final subaddresses = subaddressList.getAll();
    _subaddress.value = subaddresses.first;
    _address.value = await getAddress();
  }

  Future<String> getFilename() async => moneroWallet.getFilename();

  Future<String> getName() async => getFilename()
      .then((filename) => filename.split('/'))
      .then((splitted) => splitted.last);

  Future<String> getAddress() async => moneroWallet.getAddress(
      accountIndex: _account.value.id, addressIndex: _subaddress.value.id);

  Future<String> getSeed() async => moneroWallet.getSeed();

  Future<String> getFullBalance() async => moneroAmountToString(
      amount: moneroWallet.getFullBalance(accountIndex: _account.value.id));

  Future<String> getUnlockedBalance() async => moneroAmountToString(
      amount: moneroWallet.getUnlockedBalance(accountIndex: _account.value.id));

  Future<int> getCurrentHeight() async => moneroWallet.getCurrentHeight();

  Future<int> getNodeHeight() async => moneroWallet.getNodeHeight();

  Future<Map<String, String>> getKeys() async => {
        'publicViewKey': moneroWallet.getPublicViewKey(),
        'privateViewKey': moneroWallet.getSecretViewKey(),
        'publicSpendKey': moneroWallet.getPublicSpendKey(),
        'privateSpendKey': moneroWallet.getSecretSpendKey()
      };

  Future close() async {
    moneroWallet.closeListeners();
    moneroWallet.closeCurrentWallet();
  }

  Future connectToNode(
      {Node node, bool useSSL = false, bool isLightWallet = false}) async {
    try {
      _syncStatus.value = ConnectingSyncStatus();
      await moneroWallet.setupNode(
          address: node.uri,
          login: node.login,
          password: node.password,
          useSSL: useSSL,
          isLightWallet: isLightWallet);
      _syncStatus.value = ConnectedSyncStatus();
    } catch (e) {
      _syncStatus.value = FailedSyncStatus();
      print(e);
    }
  }

  Future startSync() async {
    try {
      _syncStatus.value = StartingSyncStatus();
      moneroWallet.startRefresh();
    } on PlatformException catch (e) {
      _syncStatus.value = FailedSyncStatus();
      print(e);
      throw e;
    }
  }

  TransactionHistory getHistory() {
    if (_cachedTransactionHistory == null) {
      _cachedTransactionHistory = MoneroTransactionHistory();
    }

    return _cachedTransactionHistory;
  }

  SubaddressList getSubaddress() {
    if (_cachedSubaddressList == null) {
      _cachedSubaddressList = SubaddressList();
    }

    return _cachedSubaddressList;
  }

  AccountList getAccountList() {
    if (_cachedAccountList == null) {
      _cachedAccountList = AccountList();
    }

    return _cachedAccountList;
  }

  Future askForSave() async {
    final diff = DateTime.now().millisecondsSinceEpoch - _lastSaveTime;

    if (_lastSaveTime != 0 && diff < 120000) {
      return;
    }

    await store();
  }

  Future<int> getNodeHeightOrUpdate(int baseHeight) async {
    if (_cachedBlockchainHeight < baseHeight) {
      _cachedBlockchainHeight = await getNodeHeight();
    }

    return _cachedBlockchainHeight;
  }

  Future<PendingTransaction> createTransaction(
      TransactionCreationCredentials credentials) async {
    MoneroTransactionCreationCredentials _credentials =
        credentials as MoneroTransactionCreationCredentials;

    final transactionDescription = await transactionHistory.createTransaction(
        address: _credentials.address,
        paymentId: _credentials.paymentId,
        amount: _credentials.amount,
        priorityRaw: _credentials.priority.serialize(),
        accountIndex: _account.value.id);

    return PendingTransaction.fromTransactionDescription(
        transactionDescription);
  }

  setRecoveringFromSeed() =>
      moneroWallet.setRecoveringFromSeed(isRecovery: true);

  setRefreshFromBlockHeight({int height}) =>
      moneroWallet.setRefreshFromBlockHeight(height: height);

  Future<bool> isConnected() async => moneroWallet.isConnected();

  Future setAsRecovered() async {
    walletInfo.isRecovery = false;
    await walletInfo.save();
  }

  Future askForUpdateBalance() async {
    final fullBalance = await getFullBalance();
    final unlockedBalance = await getUnlockedBalance();
    final needToChange = _onBalanceChange.value != null
        ? _onBalanceChange.value.fullBalance != fullBalance ||
            _onBalanceChange.value.unlockedBalance != unlockedBalance
        : true;

    if (!needToChange) {
      return;
    }

    _onBalanceChange.add(MoneroBalance(
        fullBalance: fullBalance, unlockedBalance: unlockedBalance));
  }

  Future askForUpdateTransactionHistory() async => await getHistory().update();

  Future rescan({int restoreHeight = 0}) async {
    _syncStatus.value = StartingSyncStatus();
    setRefreshFromBlockHeight(height: restoreHeight);
    moneroWallet.rescanBlockchainAsync();
    _syncStatus.value = StartingSyncStatus();
  }

  changeCurrentSubaddress(Subaddress subaddress) =>
      _subaddress.value = subaddress;

  changeAccount(Account account) {
    _account.add(account);

    getSubaddress()
        .refresh(accountIndex: account.id)
        .then((_) => getSubaddress().getAll())
        .then((subaddresses) => _subaddress.value = subaddresses[0]);
  }

  Future store() async {
    if (_isSaving) {
      return;
    }

    try {
      _isSaving = true;
      moneroWallet.store();
      _isSaving = false;
    } on PlatformException catch (e) {
      print(e);
      _isSaving = false;
      throw e;
    }
  }

  setListeners() => moneroWallet.setListeners(
      _onNewBlock, _onNeedToRefresh, _onNewTransaction);

  Future _onNewBlock(int height) async {
    try {
      final nodeHeight = await getNodeHeightOrUpdate(height);

      if (isRecovery && _refreshHeight <= 0) {
        _refreshHeight = height;
      }

      if (isRecovery &&
          (_lastSyncHeight == 0 ||
              (height - _lastSyncHeight) > monero_block_size)) {
        _lastSyncHeight = height;
        askForUpdateBalance();
        askForUpdateTransactionHistory();
      }

      if (height > 0 && ((nodeHeight - height) < monero_block_size)) {
        _syncStatus.add(SyncedSyncStatus());
      } else {
        _syncStatus.add(SyncingSyncStatus(height, nodeHeight, _refreshHeight));
      }
    } catch (e) {
      print(e);
    }
  }

  Future _onNeedToRefresh() async {
    try {
      final currentHeight = await getCurrentHeight();
      final nodeHeight = await getNodeHeightOrUpdate(currentHeight);

      // no blocks - maybe we're not connected to the node ?
      if (currentHeight <= 1 || nodeHeight == 0) {
        return;
      }

      if (_syncStatus.value is FailedSyncStatus) {
        return;
      }

      askForUpdateBalance();

      _syncStatus.add(SyncedSyncStatus());

      if (isRecovery) {
        askForUpdateTransactionHistory();
      }

      if (isRecovery && (nodeHeight - currentHeight < monero_block_size)) {
        await setAsRecovered();
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = now - _lastRefreshTime;

      if (diff >= 0 && diff < 60000) {
        return;
      }

      await store();
      _lastRefreshTime = now;
    } catch (e) {
      print(e);
    }
  }

  Future _onNewTransaction() async {
    await askForUpdateBalance();
    await askForUpdateTransactionHistory();
  }
}
