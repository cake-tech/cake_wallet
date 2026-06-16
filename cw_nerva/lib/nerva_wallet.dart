import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:cw_core/account.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/monero_wallet_keys.dart';
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/nerva_amount_format.dart';
import 'package:cw_core/nerva_balance.dart';
import 'package:cw_nerva/api/account_list.dart';
import 'package:cw_nerva/api/coins_info.dart';
import 'package:cw_nerva/api/structs/pending_transaction.dart';
import 'package:cw_nerva/api/transaction_history.dart' as transaction_history;
import 'package:cw_nerva/api/wallet.dart' as nerva_wallet;
import 'package:cw_nerva/api/wallet_manager.dart';
import 'package:cw_nerva/api/nerva_output.dart';
import 'package:cw_nerva/exceptions/nerva_transaction_creation_exception.dart';
import 'package:cw_nerva/exceptions/nerva_transaction_no_inputs_exception.dart';
import 'package:cw_nerva/pending_nerva_transaction.dart';
import 'package:cw_nerva/nerva_transaction_creation_credentials.dart';
import 'package:cw_nerva/nerva_transaction_history.dart';
import 'package:cw_nerva/nerva_transaction_info.dart';
import 'package:cw_nerva/nerva_unspent.dart';
import 'package:cw_nerva/nerva_wallet_addresses.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:monero/nerva.dart' as nerva;

part 'nerva_wallet.g.dart';

const nervaBlockSize = 1000;
// not sure if this should just be 0 but setting it higher feels safer / should catch more cases:
const MIN_RESTORE_HEIGHT = 1000;

class NervaWallet = NervaWalletBase with _$NervaWallet;

abstract class NervaWalletBase
    extends WalletBase<NervaBalance, NervaTransactionHistory, NervaTransactionInfo>
    with Store {
  NervaWalletBase(
      {required WalletInfo walletInfo, required DerivationInfo derivationInfo, required Box<UnspentCoinsInfo> unspentCoinsInfo, required String password})
      : balance = ObservableMap<CryptoCurrency, NervaBalance>.of({
          CryptoCurrency.xnv: NervaBalance(
              fullBalance: nerva_wallet.getFullBalance(accountIndex: 0),
              unlockedBalance: nerva_wallet.getFullBalance(accountIndex: 0))
        }),
        _isTransactionUpdating = false,
        _hasSyncAfterStartup = false,
        _password = password,
        isEnabledAutoGenerateSubaddress = true,
        syncStatus = NotConnectedSyncStatus(),
        unspentCoins = [],
        this.unspentCoinsInfo = unspentCoinsInfo,
        super(walletInfo, derivationInfo) {
    transactionHistory = NervaTransactionHistory();
    walletAddresses = NervaWalletAddresses(walletInfo, transactionHistory);

    _onAccountChangeReaction = reaction((_) => walletAddresses.account, (Account? account) {
      if (account == null) return;

      balance = ObservableMap<CryptoCurrency, NervaBalance>.of(<CryptoCurrency, NervaBalance>{
        currency: NervaBalance(
            fullBalance: nerva_wallet.getFullBalance(accountIndex: account.id),
            unlockedBalance: nerva_wallet.getUnlockedBalance(accountIndex: account.id))
      });
      _updateSubAddress(isEnabledAutoGenerateSubaddress, account: account);
      _askForUpdateTransactionHistory();
    });

    reaction((_) => isEnabledAutoGenerateSubaddress, (bool enabled) {
      _updateSubAddress(enabled, account: walletAddresses.account);
    });

    _onTxHistoryChangeReaction = reaction((_) => transactionHistory, (__) {
      _updateSubAddress(isEnabledAutoGenerateSubaddress, account: walletAddresses.account);
    });
  }

  static const int _autoSaveInterval = 30;

  Box<UnspentCoinsInfo> unspentCoinsInfo;

  void Function(FlutterErrorDetails)? onError;

  @override
  late NervaWalletAddresses walletAddresses;

  @override
  @observable
  bool isEnabledAutoGenerateSubaddress;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  ObservableMap<CryptoCurrency, NervaBalance> balance;

  @override
  String get seed => nerva_wallet.getSeed();

  String seedLegacy(String? language) => nerva_wallet.getSeedLegacy(language);

  String get password => _password;

  @override
  String get passphrase => nerva_wallet.getPassphrase();

  String _password;

  @override
  bool get hasRescan => true;

  @override
  MoneroWalletKeys get keys => MoneroWalletKeys(
      primaryAddress: nerva_wallet.getAddress(accountIndex: 0, addressIndex: 0),
      privateSpendKey: nerva_wallet.getSecretSpendKey(),
      privateViewKey: nerva_wallet.getSecretViewKey(),
      publicSpendKey: nerva_wallet.getPublicSpendKey(),
      publicViewKey: nerva_wallet.getPublicViewKey(),
      passphrase: nerva_wallet.getPassphrase());

  int? get restoreHeight =>
      transactionHistory.transactions.values.firstOrNull?.height ?? nerva.Wallet_getRefreshFromBlockHeight(wptr!);


  nerva_wallet.SyncListener? _listener;
  ReactionDisposer? _onAccountChangeReaction;
  ReactionDisposer? _onTxHistoryChangeReaction;
  bool _isTransactionUpdating;
  bool _hasSyncAfterStartup;
  Timer? _autoSaveTimer;
  List<NervaUnspent> unspentCoins;

  Future<void> init() async {
    await walletAddresses.init();
    balance = ObservableMap<CryptoCurrency, NervaBalance>.of(<CryptoCurrency, NervaBalance>{
      currency: NervaBalance(
          fullBalance: nerva_wallet.getFullBalance(accountIndex: walletAddresses.account!.id),
          unlockedBalance:
              nerva_wallet.getUnlockedBalance(accountIndex: walletAddresses.account!.id))
    });
    _setListeners();
    await updateTransactions();

    if (walletInfo.isRecovery) {
      nerva_wallet.setRecoveringFromSeed(isRecovery: walletInfo.isRecovery);

      if (nerva_wallet.getCurrentHeight() <= 1) {
        nerva_wallet.setRefreshFromBlockHeight(height: walletInfo.restoreHeight);
      }
    }

    _autoSaveTimer =
        Timer.periodic(Duration(seconds: _autoSaveInterval), (_) async => await save());
  }

  @override
  Future<void>? updateBalance() => null;

  @override
  Future<bool> checkNodeHealth() async {
    try {
      // Check if the wallet is currently connected to the daemon
      final isConnected = nerva_wallet.isConnectedSync();

      if (!isConnected) {
        return false; // It's not connected to daemon
      }

      // Check to get current node height to ensure daemon is responsive
      final nodeHeight = await nerva_wallet.getNodeHeight();
      return nodeHeight > 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    _listener?.stop();
    _onAccountChangeReaction?.reaction.dispose();
    _onTxHistoryChangeReaction?.reaction.dispose();
    _autoSaveTimer?.cancel();
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    String socksProxy = node.socksProxyAddress ?? '';
    printV("bootstrapped: ${CakeTor.instance!.bootstrapped}");
    printV("     enabled: ${CakeTor.instance!.enabled}");
    printV("        port: ${CakeTor.instance!.port}");
    printV("     started: ${CakeTor.instance!.started}");
    if (CakeTor.instance!.enabled) {
      socksProxy = "127.0.0.1:${CakeTor.instance!.port}";
    }
    try {
      syncStatus = ConnectingSyncStatus();
      await nerva_wallet.setupNode(
          address: node.uri.toString(),
          login: node.login,
          password: node.password,
          useSSL: node.isSSL,
          isLightWallet: false,
          // FIXME: hardcoded value
          socksProxyAddress: socksProxy);

      nerva_wallet.setTrustedDaemon(node.trusted);
      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      printV(e);
    }
  }

  @override
  Future<void> startSync() async {
    try {
      _assertInitialHeight();
    } catch (_) {
      // our restore height wasn't correct, so lets see if using the backup works:
      try {
        await resetCache(name);
        _assertInitialHeight();
      } catch (e) {
        // we still couldn't get a valid height from the backup?!:
        // try to use the date instead:
        try {
          _setHeightFromDate();
        } catch (_) {
          // we still couldn't get a valid sync height :/
        }
      }
    }

    try {
      syncStatus = AttemptingSyncStatus();
      nerva_wallet.startRefresh();
      _setListeners();
      _listener?.start();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      printV(e);
      rethrow;
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final _credentials = credentials as NervaTransactionCreationCredentials;
    final inputs = <String>[];
    final outputs = _credentials.outputs;
    final hasMultiDestination = outputs.length > 1;
    final unlockedBalance =
        nerva_wallet.getUnlockedBalance(accountIndex: walletAddresses.account!.id);
    var allInputsAmount = 0;

    PendingTransactionDescription pendingTransactionDescription;

    if (!(syncStatus is SyncedSyncStatus)) {
      throw NervaTransactionCreationException('The wallet is not synced.');
    }

    if (unspentCoins.isEmpty) {
      await updateUnspent();
    }

    for (final utx in unspentCoins) {
      if (utx.isSending) {
        allInputsAmount += utx.value;
        inputs.add(utx.keyImage!);
      }
    }
    final spendAllCoins = inputs.length == unspentCoins.length;

    if (hasMultiDestination) {
      if (outputs.any((item) => item.sendAll || (item.formattedCryptoAmount ?? 0) <= 0)) {
        throw NervaTransactionCreationException(
            'You do not have enough XNV to send this amount.');
      }

      final int totalAmount =
          outputs.fold(0, (acc, value) => acc + (value.formattedCryptoAmount ?? 0));

      final estimatedFee = calculateEstimatedFee(_credentials.priority, totalAmount);
      if (unlockedBalance < totalAmount) {
        throw NervaTransactionCreationException(
            'You do not have enough XNV to send this amount.');
      }

      if (!spendAllCoins && (allInputsAmount < totalAmount + estimatedFee)) {
        throw NervaTransactionNoInputsException(inputs.length);
      }

      final nervaOutputs = outputs.map((output) {
        final outputAddress = output.isParsedAddress ? output.extractedAddress : output.address;

        return NervaOutput(
            address: outputAddress!, amount: output.cryptoAmount!.replaceAll(',', '.'));
      }).toList();

      pendingTransactionDescription = await transaction_history.createTransactionMultDest(
          outputs: nervaOutputs,
          priorityRaw: _credentials.priority.serialize(),
          accountIndex: walletAddresses.account!.id,
          preferredInputs: inputs);
    } else {
      final output = outputs.first;
      final address = output.isParsedAddress ? output.extractedAddress : output.address;
      final amount = output.sendAll ? null : output.cryptoAmount!.replaceAll(',', '.');
      final formattedAmount = output.sendAll ? null : output.formattedCryptoAmount;

      if ((formattedAmount != null && unlockedBalance < formattedAmount) ||
          (formattedAmount == null && unlockedBalance <= 0)) {
        final formattedBalance = nervaAmountToString(amount: unlockedBalance);

        throw NervaTransactionCreationException(
            'You do not have enough unlocked balance. Unlocked: $formattedBalance. Transaction amount: ${output.cryptoAmount}.');
      }

      final estimatedFee = calculateEstimatedFee(_credentials.priority, formattedAmount);
      if (!spendAllCoins &&
          ((formattedAmount != null && allInputsAmount < (formattedAmount + estimatedFee)) ||
              formattedAmount == null)) {
        throw NervaTransactionNoInputsException(inputs.length);
      }

      pendingTransactionDescription = await transaction_history.createTransaction(
          address: address!,
          amount: amount,
          priorityRaw: _credentials.priority.serialize(),
          accountIndex: walletAddresses.account!.id,
          preferredInputs: inputs);
    }

    return PendingNervaTransaction(pendingTransactionDescription);
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
    await walletAddresses.updateUsedSubaddress();

    if (isEnabledAutoGenerateSubaddress) {
      walletAddresses.updateUnusedSubaddress(
          accountIndex: walletAddresses.account?.id ?? 0,
          defaultLabel: walletAddresses.account?.label ?? '');
    }

    await walletAddresses.updateAddressesInBox();
    await nerva_wallet.store();
    try {
      await backupWalletFiles(name);
    } catch (e) {
      printV("¯\\_(ツ)_/¯");
      printV(e);
    }
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    final currentWalletDirPath = await pathForWalletDir(name: name, type: type);
    if (openedWalletsByPath["$currentWalletDirPath/$name"] != null) {
      // NOTE: this is realistically only required on windows.
      printV("closing wallet");
      final wmaddr = wmPtr.address;
      final waddr = openedWalletsByPath["$currentWalletDirPath/$name"]!.address;
      await Isolate.run(() {
        nerva.WalletManager_closeWallet(
            Pointer.fromAddress(wmaddr), Pointer.fromAddress(waddr), true);
      });
      openedWalletsByPath.remove("$currentWalletDirPath/$name");
      printV("wallet closed");
    }
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

      await backupWalletFiles(newWalletName);
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
  Future<void> changePassword(String password) async => nerva_wallet.setPasswordSync(password);

  Future<int> getNodeHeight() async => nerva_wallet.getNodeHeight();

  Future<bool> isConnected() async => nerva_wallet.isConnected();

  Future<void> setAsRecovered() async {
    walletInfo.isRecovery = false;
    await walletInfo.save();
  }

  @override
  Future<void> rescan({required int height}) async {
    walletInfo.restoreHeight = height;
    walletInfo.isRecovery = true;
    nerva_wallet.setRefreshFromBlockHeight(height: height);
    nerva_wallet.rescanBlockchainAsync();
    await startSync();
    _askForUpdateBalance();
    walletAddresses.accountList.update();
    await _askForUpdateTransactionHistory();
    await save();
    await walletInfo.save();
  }

  Future<void> updateUnspent() async {
    try {
      refreshCoins(walletAddresses.account!.id);

      unspentCoins.clear();

      final coinCount = countOfCoins();
      for (var i = 0; i < coinCount; i++) {
        final coin = getCoin(i);
        final coinSpent = nerva.CoinsInfo_spent(coin);
        if (coinSpent == false) {
          final unspent = NervaUnspent(
            nerva.CoinsInfo_address(coin),
            nerva.CoinsInfo_hash(coin),
            nerva.CoinsInfo_keyImage(coin),
            nerva.CoinsInfo_amount(coin),
            nerva.CoinsInfo_frozen(coin),
            nerva.CoinsInfo_unlocked(coin),
          );
          if (unspent.hash.isNotEmpty) {
            unspent.isChange = transaction_history.getTransaction(unspent.hash) == 1;
          }
          unspentCoins.add(unspent);
        }
      }

      if (unspentCoinsInfo.isEmpty) {
        unspentCoins.forEach((coin) => _addCoinInfo(coin));
        return;
      }

      if (unspentCoins.isNotEmpty) {
        unspentCoins.forEach((coin) {
          final coinInfoList = unspentCoinsInfo.values.where((element) =>
              element.walletId.contains(id) &&
              element.accountIndex == walletAddresses.account!.id &&
              element.keyImage!.contains(coin.keyImage!));

          if (coinInfoList.isNotEmpty) {
            final coinInfo = coinInfoList.first;

            coin.isFrozen = coinInfo.isFrozen;
            coin.isSending = coinInfo.isSending;
            coin.note = coinInfo.note;
          } else {
            _addCoinInfo(coin);
          }
        });
      }

      await _refreshUnspentCoinsInfo();
      _askForUpdateBalance();
    } catch (e, s) {
      printV(e.toString());
      onError?.call(FlutterErrorDetails(
        exception: e,
        stack: s,
        library: this.runtimeType.toString(),
      ));
    }
  }

  Future<void> _addCoinInfo(NervaUnspent coin) async {
    final newInfo = UnspentCoinsInfo(
        walletId: id,
        hash: coin.hash,
        isFrozen: coin.isFrozen,
        isSending: coin.isSending,
        noteRaw: coin.note,
        address: coin.address,
        value: coin.value,
        vout: 0,
        keyImage: coin.keyImage,
        isChange: coin.isChange,
        accountIndex: walletAddresses.account!.id);

    await unspentCoinsInfo.add(newInfo);
  }

  Future<void> _refreshUnspentCoinsInfo() async {
    try {
      final List<dynamic> keys = <dynamic>[];
      final currentWalletUnspentCoins = unspentCoinsInfo.values.where((element) =>
          element.walletId.contains(id) && element.accountIndex == walletAddresses.account!.id);

      if (currentWalletUnspentCoins.isNotEmpty) {
        currentWalletUnspentCoins.forEach((element) {
          final existUnspentCoins =
              unspentCoins.where((coin) => element.keyImage!.contains(coin.keyImage!));

          if (existUnspentCoins.isEmpty) {
            keys.add(element.key);
          }
        });
      }

      if (keys.isNotEmpty) {
        await unspentCoinsInfo.deleteAll(keys);
      }
    } catch (e) {
      printV(e.toString());
    }
  }

  String getTransactionAddress(int accountIndex, int addressIndex) =>
      nerva_wallet.getAddress(accountIndex: accountIndex, addressIndex: addressIndex);

  @override
  Future<Map<String, NervaTransactionInfo>> fetchTransactions() async {
    transaction_history.refreshTransactions();
    return (await _getAllTransactionsOfAccount(walletAddresses.account?.id))
        .fold<Map<String, NervaTransactionInfo>>(<String, NervaTransactionInfo>{},
            (Map<String, NervaTransactionInfo> acc, NervaTransactionInfo tx) {
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
      transactionHistory.clear();
      transactionHistory.addMany(transactions);
      await transactionHistory.save();
      _isTransactionUpdating = false;
    } catch (e) {
      printV(e);
      _isTransactionUpdating = false;
    }
  }

  String getSubaddressLabel(int accountIndex, int addressIndex) =>
      nerva_wallet.getSubaddressLabel(accountIndex, addressIndex);

  Future<List<NervaTransactionInfo>> _getAllTransactionsOfAccount(int? accountIndex) async =>
      (await transaction_history
          .getAllTransactions())
          .map(
            (row) => NervaTransactionInfo(
              row.hash,
              row.blockheight,
              row.isSpend ? TransactionDirection.outgoing : TransactionDirection.incoming,
              row.timeStamp,
              row.isPending,
              row.amount,
              row.accountIndex,
              0,
              row.fee,
              row.confirmations,
            )..additionalInfo = <String, dynamic>{
                'key': row.key,
                'accountIndex': row.accountIndex,
                'addressIndex': row.addressIndex
              },
          )
          .where((element) => element.accountIndex == (accountIndex ?? 0))
          .toList();

  void _setListeners() {
    _listener?.stop();
    _listener = nerva_wallet.setListeners(_onNewBlock, _onNewTransaction);
  }

  /// Asserts the current height to be above [MIN_RESTORE_HEIGHT]
  void _assertInitialHeight() {
    if (walletInfo.isRecovery) return;

    final height = nerva_wallet.getCurrentHeight();

    // the restore height is probably correct, so we do nothing:
    if (height > MIN_RESTORE_HEIGHT) return;

    throw Exception("height isn't > $MIN_RESTORE_HEIGHT!");
  }

  void _setHeightFromDate() {
    if (walletInfo.isRecovery) {
      return;
    }

    int height = 0;
    try {
      height = _getHeightByDate(walletInfo.date);
    } catch (_) {}

    nerva_wallet.setRecoveringFromSeed(isRecovery: true);
    nerva_wallet.setRefreshFromBlockHeight(height: height);
  }

  int _getHeightDistance(DateTime date) {
    final distance = DateTime.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch;
    final daysTmp = (distance / 86400).round();
    final days = daysTmp < 1 ? 1 : daysTmp;

    return days * 1000;
  }

  int _getHeightByDate(DateTime date) {
    final nodeHeight = nerva_wallet.getNodeHeightSync();
    final heightDistance = _getHeightDistance(date);

    if (nodeHeight <= 0) {
      // the node returned 0 (an error state)
      throw Exception("nodeHeight is <= 0!");
    }

    return nodeHeight - heightDistance;
  }

  void _askForUpdateBalance() {
    final unlockedBalance = _getUnlockedBalance();
    final fullBalance = _getFullBalance();
    final frozenBalance = _getFrozenBalance();

    if (balance[currency]!.fullBalance != fullBalance ||
        balance[currency]!.unlockedBalance != unlockedBalance ||
        balance[currency]!.frozenBalance != frozenBalance) {
      balance[currency] = NervaBalance(
          fullBalance: fullBalance, unlockedBalance: unlockedBalance, frozenBalance: frozenBalance);
    }
  }

  Future<void> _askForUpdateTransactionHistory() async => await updateTransactions();

  int _getFullBalance() => nerva_wallet.getFullBalance(accountIndex: walletAddresses.account!.id);

  int _getUnlockedBalance() =>
      nerva_wallet.getUnlockedBalance(accountIndex: walletAddresses.account!.id);

  int _getFrozenBalance() {
    var frozenBalance = 0;

    for (var coin in unspentCoinsInfo.values.where((element) =>
        element.walletId == id && element.accountIndex == walletAddresses.account!.id)) {
      if (coin.isFrozen) frozenBalance += coin.value;
    }

    return frozenBalance;
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
      printV(e.toString());
    }
  }

  void _onNewTransaction() async {
    try {
      await _askForUpdateTransactionHistory();
      _askForUpdateBalance();
      await Future<void>.delayed(Duration(seconds: 1));
    } catch (e) {
      printV(e.toString());
    }
  }

  void _updateSubAddress(bool enableAutoGenerate, {Account? account}) {
    if (enableAutoGenerate) {
      walletAddresses.updateUnusedSubaddress(
        accountIndex: account?.id ?? 0,
        defaultLabel: account?.label ?? '',
      );
    } else {
      walletAddresses.updateSubaddressList(accountIndex: account?.id ?? 0);
    }
  }

  @override
  void setExceptionHandler(void Function(FlutterErrorDetails) e) => onError = e;

  @override
  Future<String> signMessage(String message, {String? address}) async {
    final useAddress = address ?? "";
    return nerva_wallet.signMessage(message, address: useAddress);
  }

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address = null}) async {
    if (address == null) return false;

    return nerva_wallet.verifyMessage(message, address, signature);
  }

  @override
  String formatCryptoAmount(String amount) {
    return nervaAmountToString(amount: int.parse(amount));
  }
}
