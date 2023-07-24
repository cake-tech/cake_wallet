import 'dart:async';
import 'dart:io';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:cw_nano/nano_balance.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/monero_wallet_keys.dart';
import 'package:cw_core/monero_balance.dart';
import 'package:cw_core/account.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/crypto_currency.dart';

part 'nano_wallet.g.dart';

const moneroBlockSize = 1000;

class NanoWallet = NanoWalletBase with _$NanoWallet;

abstract class NanoWalletBase
    extends WalletBase<NanoBalance, NanoTransactionHistory, NanoTransactionInfo> with Store {
  NanoWalletBase({required WalletInfo walletInfo})
      : balance = ObservableMap<CryptoCurrency, NanoBalance>.of({
          CryptoCurrency.nano: NanoBalance(
              currentBalance: nano_wallet.getFullBalance(accountIndex: 0),
              receivableBalance: nano_wallet.getFullBalance(accountIndex: 0))
        }),
        _isTransactionUpdating = false,
        _hasSyncAfterStartup = false,
        walletAddresses = NanoWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus(),
        super(walletInfo) {
    transactionHistory = MoneroTransactionHistory();
    _onAccountChangeReaction = reaction((_) => walletAddresses.account, (Account? account) {
      if (account == null) {
        return;
      }

      balance = ObservableMap<CryptoCurrency, MoneroBalance>.of(<CryptoCurrency, MoneroBalance>{
        currency: MoneroBalance(
            fullBalance: monero_wallet.getFullBalance(accountIndex: account.id),
            unlockedBalance: monero_wallet.getUnlockedBalance(accountIndex: account.id))
      });
      walletAddresses.updateSubaddressList(accountIndex: account.id);
    });
  }

  static const int _autoSaveInterval = 30;

  @override
  NanoWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  ObservableMap<CryptoCurrency, MoneroBalance> balance;

  @override
  String get seed => monero_wallet.getSeed();

  @override
  NanoWalletKeys get keys => NanoWalletKeys(
      privateSpendKey: monero_wallet.getSecretSpendKey(),
      privateViewKey: monero_wallet.getSecretViewKey(),
      publicSpendKey: monero_wallet.getPublicSpendKey(),
      publicViewKey: monero_wallet.getPublicViewKey());

  SyncListener? _listener;
  ReactionDisposer? _onAccountChangeReaction;
  bool _isTransactionUpdating;
  bool _hasSyncAfterStartup;
  Timer? _autoSaveTimer;

  Future<void> init() async {
    await walletAddresses.init();
    balance = ObservableMap<CryptoCurrency, MoneroBalance>.of(<CryptoCurrency, MoneroBalance>{
      currency: MoneroBalance(
          fullBalance: monero_wallet.getFullBalance(accountIndex: walletAddresses.account!.id),
          unlockedBalance:
              monero_wallet.getUnlockedBalance(accountIndex: walletAddresses.account!.id))
    });
    _setListeners();
    await updateTransactions();

    if (walletInfo.isRecovery) {
      monero_wallet.setRecoveringFromSeed(isRecovery: walletInfo.isRecovery);

      if (monero_wallet.getCurrentHeight() <= 1) {
        monero_wallet.setRefreshFromBlockHeight(height: walletInfo.restoreHeight);
      }
    }

    // _autoSaveTimer = Timer.periodic(
    //    Duration(seconds: _autoSaveInterval),
    //    (_) async => await save());
  }

  @override
  Future<void>? updateBalance() => null;

  @override
  void close() {
    _listener?.stop();
    _onAccountChangeReaction?.reaction.dispose();
    _autoSaveTimer?.cancel();
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await monero_wallet.setupNode(
          address: node.uri.toString(), useSSL: node.isSSL, isLightWallet: false);

      monero_wallet.setTrustedDaemon(node.trusted);
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
    // final _credentials = credentials as MoneroTransactionCreationCredentials;
    // return null;
    throw UnimplementedError();
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    // FIXME: hardcoded value;
    return 0;
  }

  @override
  Future<void> save() async {
    await walletAddresses.updateAddressesInBox();
    await backupWalletFiles(name);
    await monero_wallet.store();
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    final currentWalletDirPath = await pathForWalletDir(name: name, type: type);

    try {
      // -- rename the waller folder --
      final currentWalletDir = Directory(await pathForWalletDir(name: name, type: type));
      final newWalletDirPath = await pathForWalletDir(name: newWalletName, type: type);
      await currentWalletDir.rename(newWalletDirPath);

      // -- use new waller folder to rename files with old names still --
      final renamedWalletPath = newWalletDirPath + '/$name';

      final currentCacheFile = File(renamedWalletPath);
      final currentKeysFile = File('$renamedWalletPath.keys');
      final currentAddressListFile = File('$renamedWalletPath.address.txt');

      final newWalletPath = await pathForWallet(name: newWalletName, type: type);

      if (currentCacheFile.existsSync()) {
        await currentCacheFile.rename(newWalletPath);
      }
      if (currentKeysFile.existsSync()) {
        await currentKeysFile.rename('$newWalletPath.keys');
      }
      if (currentAddressListFile.existsSync()) {
        await currentAddressListFile.rename('$newWalletPath.address.txt');
      }
    } catch (e) {
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
      await Directory(currentWalletDirPath).delete(recursive: true);
    }
  }

  @override
  Future<void> changePassword(String password) async {
    monero_wallet.setPasswordSync(password);
  }

  Future<int> getNodeHeight() async => monero_wallet.getNodeHeight();

  Future<bool> isConnected() async => monero_wallet.isConnected();

  Future<void> setAsRecovered() async {
    walletInfo.isRecovery = false;
    await walletInfo.save();
  }

  @override
  Future<void> rescan({required int height}) async {
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
      monero_wallet.getAddress(accountIndex: accountIndex, addressIndex: addressIndex);

  @override
  Future<Map<String, MoneroTransactionInfo>> fetchTransactions() async {
    monero_transaction_history.refreshTransactions();
    return _getAllTransactions(null)
        .fold<Map<String, MoneroTransactionInfo>>(<String, MoneroTransactionInfo>{},
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

  String getSubaddressLabel(int accountIndex, int addressIndex) {
    return monero_wallet.getSubaddressLabel(accountIndex, addressIndex);
  }

  List<MoneroTransactionInfo> _getAllTransactions(dynamic _) => monero_transaction_history
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
    final distance = DateTime.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch;
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

    if (balance[currency]!.fullBalance != fullBalance ||
        balance[currency]!.unlockedBalance != unlockedBalance) {
      balance[currency] = MoneroBalance(fullBalance: fullBalance, unlockedBalance: unlockedBalance);
    }
  }

  Future<void> _askForUpdateTransactionHistory() async => await updateTransactions();

  int _getFullBalance() => monero_wallet.getFullBalance(accountIndex: walletAddresses.account!.id);

  int _getUnlockedBalance() =>
      monero_wallet.getUnlockedBalance(accountIndex: walletAddresses.account!.id);

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
