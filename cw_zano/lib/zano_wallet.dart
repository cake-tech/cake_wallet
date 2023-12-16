import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_zano/api/calls.dart' as calls;
import 'package:cw_zano/api/model/history.dart';
import 'package:cw_zano/api/model/zano_wallet_keys.dart';
import 'package:cw_zano/api/wallet.dart' as zano_wallet;
import 'package:cw_zano/api/zano_api.dart';
import 'package:cw_zano/pending_zano_transaction.dart';
import 'package:cw_zano/zano_balance.dart';
import 'package:cw_zano/zano_transaction_creation_credentials.dart';
import 'package:cw_zano/zano_transaction_history.dart';
import 'package:cw_zano/zano_transaction_info.dart';
import 'package:cw_zano/zano_wallet_addresses.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'zano_wallet.g.dart';

const moneroBlockSize = 1000;

class ZanoWallet = ZanoWalletBase with _$ZanoWallet;

typedef _load_wallet = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Int8);
typedef _LoadWallet = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, int);


const int zanoMixin = 10;

abstract class ZanoWalletBase
    extends WalletBase<ZanoBalance, ZanoTransactionHistory, ZanoTransactionInfo> with Store {
  ZanoWalletBase(WalletInfo walletInfo)
      : balance = ObservableMap.of({CryptoCurrency.zano: ZanoBalance(total: 0, unlocked: 0)}),
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

  List<History> history = [];
  String assetId = '';

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
  String seed = '';

  @override
  ZanoWalletKeys keys = ZanoWalletKeys(
      privateSpendKey: '', privateViewKey: '', publicSpendKey: '', publicViewKey: '');

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

  Future<void> init(String address) async {
    await walletAddresses.init();
    await walletAddresses.updateAddress(address);
    ///balance.addAll(getZanoBalance(/**accountIndex: walletAddresses.account?.id ?? 0*/));
    _setListeners();
    await updateTransactions();

    if (walletInfo.isRecovery) {
      debugPrint('setRecoveringFromSeed isRecovery ${walletInfo.isRecovery}');

      if (zano_wallet.getCurrentHeight(hWallet) <= 1) {
        debugPrint('setRefreshFromBlockHeight height ${walletInfo.restoreHeight}');
      }
    }

    _autoSaveTimer =
        Timer.periodic(Duration(seconds: _autoSaveInterval), (_) async => await save());
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
      await calls.setupNode(
        address: "195.201.107.230:33336", // node.uriRaw,
        login: "", // node.login,
        password: "", // node.password,
        useSSL: false, // node.useSSL ?? false,
        isLightWallet: false, // FIXME: hardcoded value
        /*socksProxyAddress: node.socksProxyAddress*/
      );

      //zano_wallet.setTrustedDaemon(node.trusted);
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
      debugPrint("startRefresh");
      _setListeners();
      _listener?.start(this, hWallet);
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print(e);
      rethrow;
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final creds = credentials as ZanoTransactionCreationCredentials;
    final output = creds.outputs.first;
    final address = output.isParsedAddress && (output.extractedAddress?.isNotEmpty ?? false)
        ? output.extractedAddress!
        : output.address;
    final stringAmount = output.sendAll ? null : output.cryptoAmount!.replaceAll(',', '.');
    final fee = calculateEstimatedFee(creds.priority);
    final intAmount = (double.parse(stringAmount!) * pow(10, 12)).toInt();
    final transaction = PendingZanoTransaction(fee: fee, intAmount: intAmount,
      hWallet: hWallet, address: address, assetId: assetId,
      comment: output.note ?? '', zanoWallet: this);
    return transaction;

    /*final _credentials = credentials as ZanoTransactionCreationCredentials;
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

    return PendingZanoTransaction(pendingTransactionDescription, assetType);*/
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, [int? amount = null]) {
    return calls.getCurrentTxFee(priority.raw);
  }

  @override
  Future<void> save() async {
    await walletAddresses.updateAddressesInBox();
    await backupWalletFiles(name);
    await calls.store(hWallet);
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
    calls.setPassword(hWallet: hWallet, password: password);
  }

  Future<void> setAsRecovered() async {
    walletInfo.isRecovery = false;
    await walletInfo.save();
  }

  @override
  Future<void> rescan({required int height}) async {
    walletInfo.restoreHeight = height;
    walletInfo.isRecovery = true;
    debugPrint('setRefreshFromBlockHeight height $height');
    debugPrint('rescanBlockchainAsync');
    await startSync();
    _askForUpdateBalance();
    /**walletAddresses.accountList.update();*/
    await _askForUpdateTransactionHistory();
    await save();
    await walletInfo.save();
  }

  Future<void> _refreshTransactions() async {
    final result = await calls.getRecentTxsAndInfo(hWallet: hWallet, offset: 0, count: 30);
    final map = jsonDecode(result);
    if (map == null || map["result"] == null || map["result"]["result"] == null) {
      return;
    }
    if (map["result"]["result"]["transfers"] != null)
      history = (map["result"]["result"]["transfers"] as List<dynamic>)
          .map((e) => History.fromJson(e as Map<String, dynamic>))
          .toList();
  }

  @override
  Future<Map<String, ZanoTransactionInfo>> fetchTransactions() async {
    //zano_transaction_history.refreshTransactions();
    await _refreshTransactions();
    return history
        .map<ZanoTransactionInfo>((history) => ZanoTransactionInfo.fromHistory(history))
        .fold<Map<String, ZanoTransactionInfo>>(<String, ZanoTransactionInfo>{},
            (Map<String, ZanoTransactionInfo> acc, ZanoTransactionInfo tx) {
      acc[tx.id] = tx;
      return acc;
    });
    // return _getAllTransactions(null)
    //     .fold<Map<String, ZanoTransactionInfo>>(<String, ZanoTransactionInfo>{},
    //         (Map<String, ZanoTransactionInfo> acc, ZanoTransactionInfo tx) {
    //   acc[tx.id] = tx;
    //   return acc;
    // });
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

  // List<ZanoTransactionInfo> _getAllTransactions(dynamic _) =>
  //     zano_transaction_history
  //         .getAllTransations()
  //         .map((row) => ZanoTransactionInfo.fromRow(row))
  //         .toList();

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
      debugPrint('setRecoveringFromSeed isRecovery true');
      debugPrint('setRefreshFromBlockHeight height $height');
    }
  }

  int _getHeightByDate(DateTime date) {
    return 0;
  }

  void _askForUpdateBalance() {
    debugPrint('askForUpdateBalance');
  }

  Future<void> _askForUpdateTransactionHistory() async => await updateTransactions();

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

  final _loadWalletNative =
      zanoApi.lookup<NativeFunction<_load_wallet>>('load_wallet').asFunction<_LoadWallet>();

  String loadWallet(String path, String password) {
    print('load_wallet path $path password $password');
    final pathPointer = path.toNativeUtf8();
    final passwordPointer = password.toNativeUtf8();
    final result = _convertUTF8ToString(
      pointer: _loadWalletNative(pathPointer, passwordPointer, 0),
    );
    print('load_wallet result $result');
    return result;
  }

  String _convertUTF8ToString({required Pointer<Utf8> pointer}) {
    final str = pointer.toDartString();
    calloc.free(pointer);
    return str;
  }
}
