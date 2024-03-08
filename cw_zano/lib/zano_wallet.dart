import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_zano/api/api_calls.dart';
import 'package:cw_zano/api/model/destination.dart';
import 'package:cw_zano/api/model/get_recent_txs_and_info_params.dart';
import 'package:cw_zano/api/model/get_wallet_info_result.dart';
import 'package:cw_zano/api/model/get_wallet_status_result.dart';
import 'package:cw_zano/api/model/history.dart';
import 'package:cw_zano/api/model/store_result.dart';
import 'package:cw_zano/api/model/zano_wallet_keys.dart';
import 'package:cw_zano/api/zano_api.dart';
import 'package:cw_zano/exceptions/zano_transaction_creation_exception.dart';
import 'package:cw_zano/pending_zano_transaction.dart';
import 'package:cw_zano/zano_balance.dart';
import 'package:cw_zano/zano_transaction_credentials.dart';
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

abstract class ZanoWalletBase extends WalletBase<ZanoBalance, ZanoTransactionHistory, ZanoTransactionInfo> with Store {
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
  String defaultAsssetId = '';

  static const int _autoSaveInterval = 30;
  static const _statusDelivered = 'delivered';
  static const _maxAttempts = 10;

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
  ZanoWalletKeys keys = ZanoWalletKeys(privateSpendKey: '', privateViewKey: '', publicSpendKey: '', publicViewKey: '');

  //zano_wallet.SyncListener? _listener;
  /**ReactionDisposer? _onAccountChangeReaction;*/
  Timer? _updateSyncInfoTimer;
  int _cachedBlockchainHeight = 0;
  int _lastKnownBlockHeight = 0;
  int _initialSyncHeight = 0;
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
    //_setListeners();
    await updateTransactions();

    _autoSaveTimer = Timer.periodic(Duration(seconds: _autoSaveInterval), (_) async => await save());
  }

  @override
  Future<void>? updateBalance() => null;

  @override
  void close() {
    _updateSyncInfoTimer?.cancel();
    //_listener?.stop();
    /**_onAccountChangeReaction?.reaction.dispose();*/
    _autoSaveTimer?.cancel();
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await ApiCalls.setupNode(
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
      syncStatus = AttemptingSyncStatus();
      _cachedBlockchainHeight = 0;
      _lastKnownBlockHeight = 0;
      _initialSyncHeight = 0;
      _updateSyncInfoTimer ??= Timer.periodic(Duration(milliseconds: 1200), (_) async {
        /**if (isNewTransactionExist()) {
        onNewTransaction?.call();
      }*/

        GetWalletStatusResult status = getWalletStatus();
        // You can call getWalletInfo ONLY if getWalletStatus returns NOT is in long refresh and wallet state is 2 (ready)
        if (!status.isInLongRefresh && status.walletState == 2) {
          final syncHeight = status.currentWalletHeight;

          GetWalletInfoResult result = getWalletInfo();
          seed = result.wiExtended.seed;
          keys = ZanoWalletKeys(
            privateSpendKey: result.wiExtended.spendPrivateKey,
            privateViewKey: result.wiExtended.viewPrivateKey,
            publicSpendKey: result.wiExtended.spendPublicKey,
            publicViewKey: result.wiExtended.viewPublicKey,
          );

          final _balance = result.wi.balances.first;
          defaultAsssetId = _balance.assetInfo.assetId;
          balance = ObservableMap.of({CryptoCurrency.zano: ZanoBalance(total: _balance.total, unlocked: _balance.unlocked)});

          if (_initialSyncHeight <= 0) {
            _initialSyncHeight = syncHeight;
          }

          final bchHeight = status.currentDaemonHeight;

          if (_lastKnownBlockHeight == syncHeight) {
            return;
          }

          _lastKnownBlockHeight = syncHeight;
          final track = bchHeight - _initialSyncHeight;
          final diff = track - (bchHeight - syncHeight);
          final ptc = diff <= 0 ? 0.0 : diff / track;
          final left = bchHeight - syncHeight;

          if (syncHeight < 0 || left < 0) {
            return;
          }

          // 1. Actual new height; 2. Blocks left to finish; 3. Progress in percents;
          _onNewBlock.call(syncHeight, left, ptc);
        }
      });
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print(e);
      rethrow;
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final creds = credentials as ZanoTransactionCredentials;
    final outputs = creds.outputs;
    final hasMultiDestination = outputs.length > 1;
    final unlockedBalance = balance[CryptoCurrency.zano]?.unlocked ?? 0;
    final fee = calculateEstimatedFee(creds.priority);
    late List<Destination> destinations;
    if (hasMultiDestination) {
      if (outputs.any((output) => output.sendAll || (output.formattedCryptoAmount ?? 0) <= 0)) {
        throw ZanoTransactionCreationException("You don't have enough coins.");
      }
      final int totalAmount = outputs.fold(0, (acc, value) => acc + (value.formattedCryptoAmount ?? 0));
      if (totalAmount + fee > unlockedBalance) {
        throw ZanoTransactionCreationException(
            "You don't have enough coins (required: ${moneroAmountToString(amount: totalAmount + fee)}, unlocked ${moneroAmountToString(amount: unlockedBalance)}).");
      }
      destinations = outputs
          .map((output) => Destination(
                amount: output.formattedCryptoAmount ?? 0,
                address: output.isParsedAddress ? output.extractedAddress! : output.address,
                assetId: defaultAsssetId,
              ))
          .toList();
    } else {
      final output = outputs.first;
      late int amount;
      if (output.sendAll) {
        amount = unlockedBalance - fee;
      } else {
        amount = output.formattedCryptoAmount!;
      }
      if (amount + fee > unlockedBalance) {
        throw ZanoTransactionCreationException(
            "You don't have enough coins (required: ${moneroAmountToString(amount: amount + fee)}, unlocked ${moneroAmountToString(amount: unlockedBalance)}).");
      }
      destinations = [
        Destination(
          amount: amount,
          address: output.isParsedAddress ? output.extractedAddress! : output.address,
          assetId: defaultAsssetId,
        )
      ];
    }
    return PendingZanoTransaction(
      zanoWallet: this,
      destinations: destinations,
      fee: fee,
      comment: outputs.first.note ?? '',
    );
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, [int? amount = null]) {
    return ApiCalls.getCurrentTxFee(priority: priority.raw);
  }

  @override
  Future<void> save() async {
    try {
      await walletAddresses.updateAddressesInBox();
      await backupWalletFiles(name);
      await store();
    } catch (e) {
      print('Error while saving Zano wallet file ${e.toString()}');
    }
  }

  Future<void> store() async {
    try {
      final json = await invokeMethod('store', '{}');
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (map['result'] == null || map['result']['result'] == null) {
        throw 'store empty response';
      }
      final _ = StoreResult.fromJson(map['result']['result'] as Map<String, dynamic>);
    } catch (e) {
      print(e.toString());
    }
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
    ApiCalls.setPassword(hWallet: hWallet, password: password);
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
    try {
      final result = await invokeMethod('get_recent_txs_and_info', GetRecentTxsAndInfoParams(offset: 0, count: 30));
      final map = jsonDecode(result) as Map<String, dynamic>?;
      if (map == null) {
        print('get_recent_txs_and_info empty response');
        return;
      }

      final resultData = map['result'];
      if (resultData == null) {
        print('get_recent_txs_and_info empty response');
        return;
      }

      if (resultData['error'] != null) {
        print('get_recent_txs_and_info error ${resultData['error']}');
        return;
      }

      final transfers = resultData['result']?['transfers'] as List<dynamic>?;
      if (transfers == null) {
        print('get_recent_txs_and_info empty transfers');
        return;
      }

      history = transfers.map((e) => History.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Future<Map<String, ZanoTransactionInfo>> fetchTransactions() async {
    try {
      await _refreshTransactions();
      return history.map<ZanoTransactionInfo>((history) => ZanoTransactionInfo.fromHistory(history)).fold<Map<String, ZanoTransactionInfo>>(
        <String, ZanoTransactionInfo>{},
        (Map<String, ZanoTransactionInfo> acc, ZanoTransactionInfo tx) {
          acc[tx.id] = tx;
          return acc;
        },
      );
    } catch (e) {
      print(e);
      return {};
    }
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

  // void _setListeners() {
  //   _listener?.stop();
  //   _listener = zano_wallet.setListeners(_onNewBlock, _onNewTransaction);
  // }


  void _askForUpdateBalance() {
    debugPrint('askForUpdateBalance');      // TODO: remove, also remove this method completely
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
      await Future<void>.delayed(Duration(seconds: 1)); // TODO: ???
    } catch (e) {
      print(e.toString());
    }
  }

  final _loadWalletNative = zanoApi.lookup<NativeFunction<_load_wallet>>('load_wallet').asFunction<_LoadWallet>();

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

  Future<String> invokeMethod(String methodName, Object params) async {
    var invokeResult = ApiCalls.asyncCall(methodName: 'invoke', hWallet: hWallet, params: '{"method": "$methodName","params": ${jsonEncode(params)}}');
    var map = jsonDecode(invokeResult) as Map<String, dynamic>;
    int attempts = 0;
    if (map['job_id'] != null) {
      final jobId = map['job_id'] as int;
      do {
        await Future.delayed(Duration(milliseconds: attempts < 2 ? 100 : 500));
        final result = ApiCalls.tryPullResult(jobId);
        map = jsonDecode(result) as Map<String, dynamic>;
        if (map['status'] != null && map['status'] == _statusDelivered && map['result'] != null) {
          return result;
        }
      } while (++attempts < _maxAttempts);
    }
    return invokeResult;
  }

  GetWalletInfoResult getWalletInfo() {
    final json = ApiCalls.getWalletInfo(hWallet);
    print('wallet info $json'); // TODO: remove
    final result = GetWalletInfoResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
    return result;
  }

  GetWalletStatusResult getWalletStatus() {
    final json = ApiCalls.getWalletStatus(hWallet: hWallet);
    print('wallet status $json'); // TODO: remove
    final status = GetWalletStatusResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
    return status;
  }
}
