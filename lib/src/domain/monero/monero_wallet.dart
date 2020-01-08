import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cw_monero/wallet.dart' as monero_wallet;
import 'package:cw_monero/transaction_history.dart' as transaction_history;
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

const moneroBlockSize = 1000;

class MoneroWallet extends Wallet {
  MoneroWallet({this.walletInfoSource, this.walletInfo}) {
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
    final walletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == id, orElse: () => null);
    return await configured(
        walletInfoSource: walletInfoSource, walletInfo: walletInfo);
  }

  static Future<MoneroWallet> configured(
      {@required Box<WalletInfo> walletInfoSource,
      @required WalletInfo walletInfo}) async {
    final wallet = MoneroWallet(
        walletInfoSource: walletInfoSource, walletInfo: walletInfo);

    if (walletInfo.isRecovery) {
      wallet.setRecoveringFromSeed();

      if (walletInfo.restoreHeight != null) {
        wallet.setRefreshFromBlockHeight(height: walletInfo.restoreHeight);
      }
    }

    return wallet;
  }

  @override
  String get address => _address.value;

  @override
  String get name => _name.value;

  @override
  WalletType getType() => WalletType.monero;

  @override
  Observable<SyncStatus> get syncStatus => _syncStatus.stream;

  @override
  Observable<Balance> get onBalanceChange => _onBalanceChange.stream;

  @override
  Observable<String> get onNameChange => _name.stream;

  @override
  Observable<String> get onAddressChange => _address.stream;

  Observable<Account> get onAccountChange => _account.stream;

  Observable<Subaddress> get subaddress => _subaddress.stream;

  bool get isRecovery => walletInfo.isRecovery;

  Account get account => _account.value;

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

  @override
  Future updateInfo() async {
    _name.value = await getName();
    final acccountList = getAccountList();
    acccountList.refresh();
    _account.value = acccountList.getAll().first;
    final subaddressList = getSubaddress();
    await subaddressList.refresh(
        accountIndex: _account.value != null ? _account.value.id : 0);
    final subaddresses = subaddressList.getAll();
    _subaddress.value = subaddresses.first;
    _address.value = await getAddress();
  }

  @override
  Future<String> getFilename() async => monero_wallet.getFilename();

  @override
  Future<String> getName() async => getFilename()
      .then((filename) => filename.split('/'))
      .then((splitted) => splitted.last);

  @override
  Future<String> getAddress() async => monero_wallet.getAddress(
      accountIndex: _account.value.id, addressIndex: _subaddress.value.id);

  @override
  Future<String> getSeed() async => monero_wallet.getSeed();

  @override
  Future<String> getFullBalance() async => moneroAmountToString(
      amount: monero_wallet.getFullBalance(accountIndex: _account.value.id));

  @override
  Future<String> getUnlockedBalance() async => moneroAmountToString(
      amount:
          monero_wallet.getUnlockedBalance(accountIndex: _account.value.id));

  @override
  Future<int> getCurrentHeight() async => monero_wallet.getCurrentHeight();

  @override
  Future<int> getNodeHeight() async => monero_wallet.getNodeHeight();

  @override
  Future<bool> isConnected() async => monero_wallet.isConnected();

  @override
  Future<Map<String, String>> getKeys() async => {
        'publicViewKey': monero_wallet.getPublicViewKey(),
        'privateViewKey': monero_wallet.getSecretViewKey(),
        'publicSpendKey': monero_wallet.getPublicSpendKey(),
        'privateSpendKey': monero_wallet.getSecretSpendKey()
      };

  @override
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

  @override
  Future close() async {
    monero_wallet.closeListeners();
    monero_wallet.closeCurrentWallet();
    await _name.close();
    await _address.close();
    await _subaddress.close();
  }

  @override
  Future connectToNode(
      {Node node, bool useSSL = false, bool isLightWallet = false}) async {
    try {
      _syncStatus.value = ConnectingSyncStatus();
      await monero_wallet.setupNode(
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

  @override
  Future startSync() async {
    try {
      _syncStatus.value = StartingSyncStatus();
      monero_wallet.startRefresh();
    } on PlatformException catch (e) {
      _syncStatus.value = FailedSyncStatus();
      print(e);
      rethrow;
    }
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

  @override
  Future<PendingTransaction> createTransaction(
      TransactionCreationCredentials credentials) async {
    final _credentials = credentials as MoneroTransactionCreationCredentials;
    final transactionDescription = await transaction_history.createTransaction(
        address: _credentials.address,
        paymentId: _credentials.paymentId,
        amount: _credentials.amount,
        priorityRaw: _credentials.priority.serialize(),
        accountIndex: _account.value.id);

    return PendingTransaction.fromTransactionDescription(
        transactionDescription);
  }

  @override
  Future rescan({int restoreHeight = 0}) async {
    _syncStatus.value = StartingSyncStatus();
    setRefreshFromBlockHeight(height: restoreHeight);
    monero_wallet.rescanBlockchainAsync();
    _syncStatus.value = StartingSyncStatus();
  }

  void setRecoveringFromSeed() =>
      monero_wallet.setRecoveringFromSeed(isRecovery: true);

  void setRefreshFromBlockHeight({int height}) =>
      monero_wallet.setRefreshFromBlockHeight(height: height);

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

  void changeCurrentSubaddress(Subaddress subaddress) =>
      _subaddress.value = subaddress;

  void changeAccount(Account account) {
    _account.add(account);

    getSubaddress()
        .refresh(accountIndex: account.id)
        .then((dynamic _) => getSubaddress().getAll())
        .then((subaddresses) => _subaddress.value = subaddresses[0]);
  }

  Future store() async {
    if (_isSaving) {
      return;
    }

    try {
      _isSaving = true;
      await monero_wallet.store();
      _isSaving = false;
    } on PlatformException catch (e) {
      print(e);
      _isSaving = false;
      rethrow;
    }
  }

  void setListeners() => monero_wallet.setListeners(
      _onNewBlock, _onNeedToRefresh, _onNewTransaction);

  Future _onNewBlock(int height) async {
    try {
      final nodeHeight = await getNodeHeightOrUpdate(height);

      if (isRecovery && _refreshHeight <= 0) {
        _refreshHeight = height;
      }

      if (isRecovery &&
          (_lastSyncHeight == 0 ||
              (height - _lastSyncHeight) > moneroBlockSize)) {
        _lastSyncHeight = height;
        await askForUpdateBalance();
        await askForUpdateTransactionHistory();
      }

      if (height > 0 && ((nodeHeight - height) < moneroBlockSize)) {
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

      await askForUpdateBalance();

      _syncStatus.add(SyncedSyncStatus());

      if (isRecovery) {
        await askForUpdateTransactionHistory();
      }

      if (isRecovery && (nodeHeight - currentHeight < moneroBlockSize)) {
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
