import 'dart:async';
import 'dart:io';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_salvium/salvium_transaction_creation_credentials.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_salvium/salvium_transaction_creation_exception.dart';
import 'package:cw_salvium/salvium_transaction_info.dart';
import 'package:cw_salvium/salvium_wallet_addresses.dart';
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:cw_salvium/api/structs/pending_transaction.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_salvium/api/transaction_history.dart' as transaction_history;
import 'package:cw_salvium/api/wallet.dart' as salvium_wallet;
import 'package:cw_salvium/api/monero_output.dart';
import 'package:cw_salvium/pending_salvium_transaction.dart';
import 'package:cw_core/monero_wallet_keys.dart';
import 'package:cw_core/monero_balance.dart';
import 'package:cw_salvium/salvium_transaction_history.dart';
import 'package:cw_core/account.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_salvium/salvium_balance.dart';

part 'salvium_wallet.g.dart';

const moneroBlockSize = 1000;

class SalviumWallet = SalviumWalletBase with _$SalviumWallet;

abstract class SalviumWalletBase extends WalletBase<MoneroBalance,
    SalviumTransactionHistory, SalviumTransactionInfo> with Store {
  SalviumWalletBase({required WalletInfo walletInfo, String? password})
      : balance = ObservableMap.of(getSalviumBalance(accountIndex: 0)),
        _isTransactionUpdating = false,
        _password = password ?? '',
        _hasSyncAfterStartup = false,
        walletAddresses = SalviumWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus(),
        super(walletInfo) {
    transactionHistory = SalviumTransactionHistory();
    _onAccountChangeReaction =
        reaction((_) => walletAddresses.account, (Account? account) {
      if (account == null) {
        return;
      }
      balance.addAll(getSalviumBalance(accountIndex: account.id));
      walletAddresses.updateSubaddressList(accountIndex: account.id);
    });
  }

  static const int _autoSaveInterval = 30;
  final String _password;

  @override
  SalviumWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  ObservableMap<CryptoCurrency, MoneroBalance> balance;

  @override
  String get seed => salvium_wallet.getSeed();

  @override
  MoneroWalletKeys get keys => MoneroWalletKeys(
      primaryAddress:
          salvium_wallet.getAddress(accountIndex: 0, addressIndex: 0),
      privateSpendKey: salvium_wallet.getSecretSpendKey(),
      privateViewKey: salvium_wallet.getSecretViewKey(),
      publicSpendKey: salvium_wallet.getPublicSpendKey(),
      publicViewKey: salvium_wallet.getPublicViewKey());

  salvium_wallet.SyncListener? _listener;
  ReactionDisposer? _onAccountChangeReaction;
  bool _isTransactionUpdating;
  bool _hasSyncAfterStartup;
  Timer? _autoSaveTimer;

  Future<void> init() async {
    await walletAddresses.init();
    balance.addAll(
        getSalviumBalance(accountIndex: walletAddresses.account?.id ?? 0));
    _setListeners();
    await updateTransactions();

    if (walletInfo.isRecovery) {
      salvium_wallet.setRecoveringFromSeed(isRecovery: walletInfo.isRecovery);

      if (salvium_wallet.getCurrentHeight() <= 1) {
        salvium_wallet.setRefreshFromBlockHeight(
            height: walletInfo.restoreHeight);
      }
    }

    _autoSaveTimer = Timer.periodic(
        Duration(seconds: _autoSaveInterval), (_) async => await save());
  }

  @override
  Future<void>? updateBalance() => null;

  @override
  Future<void> close({required bool shouldCleanup}) async {
    _listener?.stop();
    _onAccountChangeReaction?.reaction.dispose();
    _autoSaveTimer?.cancel();
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await salvium_wallet.setupNode(
          address: node.uriRaw,
          login: node.login,
          password: node.password,
          useSSL: node.useSSL ?? false,
          isLightWallet: false,
          // FIXME: hardcoded value
          socksProxyAddress: node.socksProxyAddress);

      salvium_wallet.setTrustedDaemon(node.trusted);
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
      salvium_wallet.startRefresh();
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
    final _credentials = credentials as SalviumTransactionCreationCredentials;
    final outputs = _credentials.outputs;
    final hasMultiDestination = outputs.length > 1;
    final assetType =
        CryptoCurrency.fromString(_credentials.assetType.toLowerCase());
    final balances =
        getSalviumBalance(accountIndex: walletAddresses.account!.id);
    final unlockedBalance = balances[assetType]!.unlockedBalance;

    PendingTransactionDescription pendingTransactionDescription;

    if (!(syncStatus is SyncedSyncStatus)) {
      throw SalviumTransactionCreationException('The wallet is not synced.');
    }

    if (hasMultiDestination) {
      if (outputs.any(
          (item) => item.sendAll || (item.formattedCryptoAmount ?? 0) <= 0)) {
        throw SalviumTransactionCreationException(
            'You do not have enough coins to send this amount.');
      }

      final int totalAmount = outputs.fold(
          0, (acc, value) => acc + (value.formattedCryptoAmount ?? 0));

      if (unlockedBalance < totalAmount) {
        throw SalviumTransactionCreationException(
            'You do not have enough coins to send this amount.');
      }

      final moneroOutputs = outputs
          .map((output) => MoneroOutput(
              address: output.address,
              amount: output.cryptoAmount!.replaceAll(',', '.')))
          .toList();

      pendingTransactionDescription =
          await transaction_history.createTransactionMultDest(
              outputs: moneroOutputs,
              priorityRaw: _credentials.priority.serialize(),
              accountIndex: walletAddresses.account!.id);
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

        throw SalviumTransactionCreationException(
            'You do not have enough unlocked balance. Unlocked: $formattedBalance. Transaction amount: ${output.cryptoAmount}.');
      }

      pendingTransactionDescription =
          await transaction_history.createTransaction(
              address: address,
              assetType: _credentials.assetType,
              amount: amount,
              priorityRaw: _credentials.priority.serialize(),
              accountIndex: walletAddresses.account!.id);
    }

    return PendingSalviumTransaction(pendingTransactionDescription, assetType);
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
    await salvium_wallet.store();
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
    salvium_wallet.setPasswordSync(password);
  }

  Future<int> getNodeHeight() async => salvium_wallet.getNodeHeight();

  Future<bool> isConnected() async => salvium_wallet.isConnected();

  Future<void> setAsRecovered() async {
    walletInfo.isRecovery = false;
    await walletInfo.save();
  }

  @override
  Future<void> rescan({required int height}) async {
    walletInfo.restoreHeight = height;
    walletInfo.isRecovery = true;
    salvium_wallet.setRefreshFromBlockHeight(height: height);
    salvium_wallet.rescanBlockchainAsync();
    await startSync();
    _askForUpdateBalance();
    walletAddresses.accountList.update();
    await _askForUpdateTransactionHistory();
    await save();
    await walletInfo.save();
  }

  String getTransactionAddress(int accountIndex, int addressIndex) =>
      salvium_wallet.getAddress(
          accountIndex: accountIndex, addressIndex: addressIndex);

  @override
  Future<Map<String, SalviumTransactionInfo>> fetchTransactions() async {
    transaction_history.refreshTransactions();
    return _getAllTransactions(null).fold<Map<String, SalviumTransactionInfo>>(
        <String, SalviumTransactionInfo>{},
        (Map<String, SalviumTransactionInfo> acc, SalviumTransactionInfo tx) {
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

  List<SalviumTransactionInfo> _getAllTransactions(dynamic _) =>
      transaction_history
          .getAllTransations()
          .map((row) => SalviumTransactionInfo.fromRow(row))
          .toList();

  void _setListeners() {
    _listener?.stop();
    _listener = salvium_wallet.setListeners(_onNewBlock, _onNewTransaction);
  }

  void _setInitialHeight() {
    if (walletInfo.isRecovery) {
      return;
    }

    final currentHeight = salvium_wallet.getCurrentHeight();

    if (currentHeight <= 1) {
      final height = _getHeightByDate(walletInfo.date);
      salvium_wallet.setRecoveringFromSeed(isRecovery: true);
      salvium_wallet.setRefreshFromBlockHeight(height: height);
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
    final nodeHeight = salvium_wallet.getNodeHeightSync();
    final heightDistance = _getHeightDistance(date);

    if (nodeHeight <= 0) {
      return 0;
    }

    return nodeHeight - heightDistance;
  }

  void _askForUpdateBalance() => balance
      .addAll(getSalviumBalance(accountIndex: walletAddresses.account!.id));

  Future<void> _askForUpdateTransactionHistory() async =>
      await updateTransactions();

  void _onNewBlock(int height, int blocksLeft, double ptc) async {
    try {
      if (walletInfo.isRecovery) {
        await _askForUpdateTransactionHistory();
        _askForUpdateBalance();
        walletAddresses.accountList.update();
      }

      if (blocksLeft < 1000) {
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

  @override
  String get password => _password;

  @override
  Future<String> signMessage(String message, {String? address = null}) =>
      throw UnimplementedError();

  @override
  Future<bool> verifyMessage(String message, String signature,
          {String? address = null}) =>
      throw UnimplementedError();
}
