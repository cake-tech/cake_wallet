import 'dart:async';
import 'dart:io';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_zano/api/zano_output.dart';
import 'package:cw_zano/zano_transaction_creation_credentials.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_zano/zano_transaction_creation_exception.dart';
import 'package:cw_zano/zano_transaction_info.dart';
import 'package:cw_zano/zano_wallet_addresses.dart';
import 'package:cw_zano/api/calls.dart' as calls;
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:cw_zano/api/structs/pending_transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_zano/api/transaction_history.dart'
    as zano_transaction_history;
//import 'package:cw_zano/wallet.dart';
import 'package:cw_zano/api/wallet.dart' as zano_wallet;
import 'package:cw_zano/api/transaction_history.dart' as transaction_history;
import 'package:cw_zano/api/zano_output.dart';
import 'package:cw_zano/pending_zano_transaction.dart';
import 'package:cw_core/monero_wallet_keys.dart';
import 'package:cw_core/monero_balance.dart';
import 'package:cw_zano/zano_transaction_history.dart';
import 'package:cw_core/account.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_zano/zano_balance.dart';

part 'zano_wallet.g.dart';

const moneroBlockSize = 1000;

class ZanoWallet = ZanoWalletBase with _$ZanoWallet;

abstract class ZanoWalletBase
    extends WalletBase<ZanoBalance, ZanoTransactionHistory, ZanoTransactionInfo>
    with Store {
  ZanoWalletBase.simple({required WalletInfo walletInfo})
      : balance = ObservableMap(),
        _isTransactionUpdating = false,
        _hasSyncAfterStartup = false,
        walletAddresses = ZanoWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus(),
        super(walletInfo) {
          transactionHistory = ZanoTransactionHistory();
        }

  ZanoWalletBase({required WalletInfo walletInfo})
      : balance = ObservableMap.of({CryptoCurrency.zano: ZanoBalance(0, 0)}),
        _isTransactionUpdating = false,
        _hasSyncAfterStartup = false,
        walletAddresses = ZanoWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus(),
        super(walletInfo) {
    transactionHistory = ZanoTransactionHistory();
    /*_onAccountChangeReaction =
        reaction((_) => walletAddresses.account, (Account? account) {
      if (account == null) {
        return;
      }
      balance.addAll(getZanoBalance(accountIndex: account.id));
      /**walletAddresses.updateSubaddressList(accountIndex: account.id);*/
    });*/
  }

  static const int _autoSaveInterval = 30;

  @override
  ZanoWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  ObservableMap<CryptoCurrency, ZanoBalance> balance;

  @override
  String get seed {
    // TODO: fix it
    //return calls.seed(hWallet);
    return "test";
    /**zano_wallet.getSeed();*/
  }

  @override
  // TODO: ?? why monero
  MoneroWalletKeys get keys => MoneroWalletKeys(
      privateSpendKey: zano_wallet.getSecretSpendKey(),
      privateViewKey: zano_wallet.getSecretViewKey(),
      publicSpendKey: zano_wallet.getPublicSpendKey(),
      publicViewKey: zano_wallet.getPublicViewKey());

  zano_wallet.SyncListener? _listener;
  /**ReactionDisposer? _onAccountChangeReaction;*/
  bool _isTransactionUpdating;
  bool _hasSyncAfterStartup;
  Timer? _autoSaveTimer;

  int _hWallet = 0;

  int get hWallet => _hWallet;

  set hWallet(int value) {
    _hWallet = value;
  }

  Future<void> init() async {
    await walletAddresses.init();
    balance
        .addAll(getZanoBalance(/**accountIndex: walletAddresses.account?.id ?? 0*/));
    _setListeners();
    await updateTransactions();

    if (walletInfo.isRecovery) {
      zano_wallet.setRecoveringFromSeed(isRecovery: walletInfo.isRecovery);

      if (zano_wallet.getCurrentHeight(hWallet) <= 1) {
        zano_wallet.setRefreshFromBlockHeight(height: walletInfo.restoreHeight);
      }
    }

    _autoSaveTimer = Timer.periodic(
        Duration(seconds: _autoSaveInterval), (_) async => await save());
  }

  @override
  Future<void>? updateBalance() => null;

  @override
  void close() {
    _listener?.stop();
    /**_onAccountChangeReaction?.reaction.dispose();*/
    _autoSaveTimer?.cancel();
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await zano_wallet.setupNode(
        address: "195.201.107.230:33336", // node.uriRaw,
        login: "", // node.login,
        password: "", // node.password,
        useSSL: false, // node.useSSL ?? false,
        isLightWallet: false, // FIXME: hardcoded value
        /*socksProxyAddress: node.socksProxyAddress*/
      );

      zano_wallet.setTrustedDaemon(node.trusted);
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
      syncStatus = AttemptingSyncStatus();
      zano_wallet.startRefresh();
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
    final _credentials = credentials as ZanoTransactionCreationCredentials;
    final outputs = _credentials.outputs;
    final hasMultiDestination = outputs.length > 1;
    final assetType =
        CryptoCurrency.fromString(_credentials.assetType.toLowerCase());
    final balances = getZanoBalance(/*accountIndex: walletAddresses.account!.id*/);
    final unlockedBalance = balances[assetType]!.unlockedBalance;

    PendingTransactionDescription pendingTransactionDescription;

    if (!(syncStatus is SyncedSyncStatus)) {
      throw ZanoTransactionCreationException('The wallet is not synced.');
    }

    if (hasMultiDestination) {
      if (outputs.any(
          (item) => item.sendAll || (item.formattedCryptoAmount ?? 0) <= 0)) {
        throw ZanoTransactionCreationException(
            'You do not have enough coins to send this amount.');
      }

      final int totalAmount = outputs.fold(
          0, (acc, value) => acc + (value.formattedCryptoAmount ?? 0));

      if (unlockedBalance < totalAmount) {
        throw ZanoTransactionCreationException(
            'You do not have enough coins to send this amount.');
      }

      final zanoOutputs = outputs
          .map((output) => ZanoOutput(
              address: output.address,
              amount: output.cryptoAmount!.replaceAll(',', '.')))
          .toList();

      pendingTransactionDescription =
          await transaction_history.createTransactionMultDest(
              outputs: zanoOutputs,
              priorityRaw: _credentials.priority.serialize());
    } else {
      final output = outputs.first;
      final address = output.isParsedAddress &&
              (output.extractedAddress?.isNotEmpty ?? false)
          ? output.extractedAddress!
          : output.address;
      final amount =
          output.sendAll ? null : output.cryptoAmount!.replaceAll(',', '.');
      final int? formattedAmount =
          output.sendAll ? null : output.formattedCryptoAmount;

      if ((formattedAmount != null && unlockedBalance < formattedAmount) ||
          (formattedAmount == null && unlockedBalance <= 0)) {
        final formattedBalance = moneroAmountToString(amount: unlockedBalance);

        throw ZanoTransactionCreationException(
            'You do not have enough unlocked balance. Unlocked: $formattedBalance. Transaction amount: ${output.cryptoAmount}.');
      }

      pendingTransactionDescription =
          await transaction_history.createTransaction(
              address: address,
              assetType: _credentials.assetType,
              amount: amount,
              priorityRaw: _credentials.priority.serialize());
    }

    return PendingZanoTransaction(pendingTransactionDescription, assetType);
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    // FIXME: hardcoded value;

    if (priority is MoneroTransactionPriority) {
      switch (priority) {
        case MoneroTransactionPriority.slow:
          return 24590000;
        case MoneroTransactionPriority.automatic:
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
    await backupWalletFiles(name);
    await zano_wallet.store(hWallet);
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    final currentWalletPath = await pathForWallet(name: name, type: type);
    final currentCacheFile = File(currentWalletPath);
    final currentKeysFile = File('$currentWalletPath.keys');
    final currentAddressListFile = File('$currentWalletPath.address.txt');

    final newWalletPath = await pathForWallet(name: newWalletName, type: type);

    // Copies current wallet files into new wallet name's dir and files
    if (currentCacheFile.existsSync()) {
      await currentCacheFile.copy(newWalletPath);
    }
    if (currentKeysFile.existsSync()) {
      await currentKeysFile.copy('$newWalletPath.keys');
    }
    if (currentAddressListFile.existsSync()) {
      await currentAddressListFile.copy('$newWalletPath.address.txt');
    }

    // Delete old name's dir and files
    await Directory(currentWalletPath).delete(recursive: true);
  }

  @override
  Future<void> changePassword(String password) async {
    zano_wallet.setPasswordSync(password);
  }

  Future<int> getNodeHeight() async => zano_wallet.getNodeHeight();

  Future<bool> isConnected() async => zano_wallet.isConnected();

  Future<void> setAsRecovered() async {
    walletInfo.isRecovery = false;
    await walletInfo.save();
  }

  @override
  Future<void> rescan({required int height}) async {
    walletInfo.restoreHeight = height;
    walletInfo.isRecovery = true;
    zano_wallet.setRefreshFromBlockHeight(height: height);
    zano_wallet.rescanBlockchainAsync();
    await startSync();
    _askForUpdateBalance();
    /**walletAddresses.accountList.update();*/
    await _askForUpdateTransactionHistory();
    await save();
    await walletInfo.save();
  }

  String getTransactionAddress(int accountIndex, int addressIndex) =>
      zano_wallet.getAddress(
          accountIndex: accountIndex, addressIndex: addressIndex);

  @override
  Future<Map<String, ZanoTransactionInfo>> fetchTransactions() async {
    zano_transaction_history.refreshTransactions();
    return _getAllTransactions(null)
        .fold<Map<String, ZanoTransactionInfo>>(<String, ZanoTransactionInfo>{},
            (Map<String, ZanoTransactionInfo> acc, ZanoTransactionInfo tx) {
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

  List<ZanoTransactionInfo> _getAllTransactions(dynamic _) =>
      zano_transaction_history
          .getAllTransations()
          .map((row) => ZanoTransactionInfo.fromRow(row))
          .toList();

  void _setListeners() {
    _listener?.stop();
    _listener = zano_wallet.setListeners(_onNewBlock, _onNewTransaction);
  }

  void _setInitialHeight() {
    if (walletInfo.isRecovery) {
      return;
    }

    final currentHeight = zano_wallet.getCurrentHeight(hWallet);

    if (currentHeight <= 1) {
      final height = _getHeightByDate(walletInfo.date);
      zano_wallet.setRecoveringFromSeed(isRecovery: true);
      zano_wallet.setRefreshFromBlockHeight(height: height);
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
    final nodeHeight = zano_wallet.getNodeHeightSync();
    final heightDistance = _getHeightDistance(date);

    if (nodeHeight <= 0) {
      return 0;
    }

    return nodeHeight - heightDistance;
  }

  void _askForUpdateBalance() =>
      balance.addAll(getZanoBalance());

  Future<void> _askForUpdateTransactionHistory() async =>
      await updateTransactions();

  void _onNewBlock(int height, int blocksLeft, double ptc) async {
    try {
      if (walletInfo.isRecovery) {
        await _askForUpdateTransactionHistory();
        _askForUpdateBalance();
        /*walletAddresses.accountList.update();*/
      }

      if (blocksLeft < 1000) {
        await _askForUpdateTransactionHistory();
        _askForUpdateBalance();
        /*walletAddresses.accountList.update();*/
        syncStatus = SyncedSyncStatus();

        if (!_hasSyncAfterStartup) {
          _hasSyncAfterStartup = true;
          await save();
        }

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
    } catch (e) {
      print(e.toString());
    }
  }
}
