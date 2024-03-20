import 'dart:async';
import 'dart:io';

import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
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
import 'package:cw_zano/api/model/get_wallet_status_result.dart';
import 'package:cw_zano/api/model/transfer.dart';
import 'package:cw_zano/model/zano_wallet_keys.dart';
import 'package:cw_zano/model/zano_transaction_creation_exception.dart';
import 'package:cw_zano/model/pending_zano_transaction.dart';
import 'package:cw_zano/model/zano_asset.dart';
import 'package:cw_zano/model/zano_balance.dart';
import 'package:cw_zano/zano_formatter.dart';
import 'package:cw_zano/model/zano_transaction_credentials.dart';
import 'package:cw_zano/zano_transaction_history.dart';
import 'package:cw_zano/model/zano_transaction_info.dart';
import 'package:cw_zano/zano_wallet_addresses.dart';
import 'package:cw_zano/zano_wallet_api.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

import 'default_zano_assets.dart';

part 'zano_wallet.g.dart';

const int zanoMixinValue = 10;

class ZanoWallet = ZanoWalletBase with _$ZanoWallet;

abstract class ZanoWalletBase extends WalletBase<ZanoBalance, ZanoTransactionHistory, ZanoTransactionInfo> with Store, ZanoWalletApi {
  static const int _autoSaveInterval = 30;

  List<Transfer> transfers = [];
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

  static const String zanoAssetId = 'd6329b5b1f7c0805b5c345f4957554002a2f557845f64d7645dae0e051a6498a';
  late final Box<ZanoAsset> zanoAssetsBox;
  List<ZanoAsset> get zanoAssets => zanoAssetsBox.values.toList();

  //zano_wallet.SyncListener? _listener;
  // ReactionDisposer? _onAccountChangeReaction;
  Timer? _updateSyncInfoTimer;

  int _cachedBlockchainHeight = 0;
  int _lastKnownBlockHeight = 0;
  int _initialSyncHeight = 0;
  bool _isTransactionUpdating;
  bool _hasSyncAfterStartup;
  Timer? _autoSaveTimer;

  ZanoWalletBase(WalletInfo walletInfo)
      : balance = ObservableMap.of({CryptoCurrency.zano: ZanoBalance(total: 0, unlocked: 0, decimalPoint: ZanoFormatter.defaultDecimalPoint)}),
        _isTransactionUpdating = false,
        _hasSyncAfterStartup = false,
        walletAddresses = ZanoWalletAddresses(walletInfo),
        syncStatus = NotConnectedSyncStatus(),
        super(walletInfo) {
    transactionHistory = ZanoTransactionHistory();
    if (!CakeHive.isAdapterRegistered(ZanoAsset.typeId)) {
      CakeHive.registerAdapter(ZanoAssetAdapter());
    }
    // _onAccountChangeReaction =
    //     reaction((_) => walletAddresses.account, (Account? account) {
    //   if (account == null) {
    //     return;
    //   }
    //   balance.addAll(getZanoBalance(accountIndex: account.id));
    //   /**walletAddresses.updateSubaddressList(accountIndex: account.id);*/
    // });
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, [int? amount = null]) => getCurrentTxFee(priority);

  @override
  Future<void> changePassword(String password) async {
    setPassword(password);
  }

  @override
  void close() {
    closeWallet();
    _updateSyncInfoTimer?.cancel();
    //_listener?.stop();
    // _onAccountChangeReaction?.reaction.dispose();
    _autoSaveTimer?.cancel();
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    syncStatus = ConnectingSyncStatus();
    await setupNode();
    syncStatus = ConnectedSyncStatus();
    // if (await setupNode() == false) {
    //   syncStatus = FailedSyncStatus();
    //   // TODO: what's going on?
    //   //throw 'error connecting to zano node';
    // } else {
    //   syncStatus = ConnectedSyncStatus();
    // }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    credentials as ZanoTransactionCredentials;
    final isZano = credentials.currency == CryptoCurrency.zano;
    final outputs = credentials.outputs;
    final hasMultiDestination = outputs.length > 1;
    final unlockedBalanceZano = BigInt.from(balance[CryptoCurrency.zano]?.unlocked ?? 0);
    final unlockedBalanceCurrency = BigInt.from(balance[credentials.currency]?.unlocked ?? 0);
    final fee = BigInt.from(calculateEstimatedFee(credentials.priority));
    late BigInt totalAmount;
    void checkForEnoughBalances() {
      if (isZano) {
        if (totalAmount + fee > unlockedBalanceZano) {
          throw ZanoTransactionCreationException(
              "You don't have enough coins (required: ${ZanoFormatter.bigIntAmountToString(totalAmount + fee)} ZANO, unlocked ${ZanoFormatter.bigIntAmountToString(unlockedBalanceZano)} ZANO).");
        }
      } else {
        if (fee > unlockedBalanceZano) {
          throw ZanoTransactionCreationException(
              "You don't have enough coins (required: ${ZanoFormatter.bigIntAmountToString(fee)} ZANO, unlocked ${ZanoFormatter.bigIntAmountToString(unlockedBalanceZano)} ZANO).");
        }
        if (totalAmount > unlockedBalanceCurrency) {
          throw ZanoTransactionCreationException(
              "You don't have enough coins (required: ${ZanoFormatter.bigIntAmountToString(totalAmount)} ${credentials.currency.title}, unlocked ${ZanoFormatter.bigIntAmountToString(unlockedBalanceZano)} ${credentials.currency.title}).");
        }
      }
    }

    final assetId = isZano ? zanoAssetId : (credentials.currency as ZanoAsset).assetId;
    late List<Destination> destinations;
    if (hasMultiDestination) {
      if (outputs.any((output) => output.sendAll || (output.formattedCryptoAmount ?? 0) <= 0)) {
        throw ZanoTransactionCreationException("You don't have enough coins.");
      }
      totalAmount = outputs.fold(BigInt.zero, (acc, value) => acc + BigInt.from(value.formattedCryptoAmount ?? 0));
      checkForEnoughBalances();
      destinations = outputs
          .map((output) => Destination(
                amount: BigInt.from(output.formattedCryptoAmount ?? 0),
                address: output.isParsedAddress ? output.extractedAddress! : output.address,
                assetId: assetId,
              ))
          .toList();
    } else {
      final output = outputs.first;
      if (output.sendAll) {
        if (isZano) {
          totalAmount = unlockedBalanceZano - fee;
        } else {
          totalAmount = unlockedBalanceCurrency;
        }
      } else {
        totalAmount = BigInt.from(output.formattedCryptoAmount!);
      }
      checkForEnoughBalances();
      destinations = [
        Destination(
          amount: totalAmount,
          address: output.isParsedAddress ? output.extractedAddress! : output.address,
          assetId: assetId,
        )
      ];
    }
    destinations.forEach((destination) {
      debugPrint('destination ${destination.address} ${destination.amount} ${destination.assetId}');
    });
    return PendingZanoTransaction(
      zanoWallet: this,
      destinations: destinations,
      fee: fee,
      comment: outputs.first.note ?? '',
      assetId: assetId,
      ticker: credentials.currency.title,
      decimalPoint: credentials.currency.decimals,
      amount: totalAmount,
    );
  }

  @override
  Future<Map<String, ZanoTransactionInfo>> fetchTransactions() async {
    try {
      transfers = await getRecentTxsAndInfo();
      return Map.fromIterable(
        transfers,
        key: (item) => (item as Transfer).txHash,
        value: (item) {
          item as Transfer;
          if (item.subtransfers.first.assetId == zanoAssetId) {
            return ZanoTransactionInfo.fromTransfer(item, 'ZANO', ZanoFormatter.defaultDecimalPoint);
          } else {
            final asset = zanoAssets.firstWhere((element) => element.assetId == item.subtransfers.first.assetId);
            return ZanoTransactionInfo.fromTransfer(item, asset.ticker, asset.decimalPoint);
          }
        },
      );
    } catch (e) {
      print(e);
      return {};
    }
  }

  Future<void> init(String address) async {
    final boxName = '${walletInfo.name.replaceAll(' ', '_')}_${ZanoAsset.zanoAssetsBoxName}';
    zanoAssetsBox = await CakeHive.openBox<ZanoAsset>(boxName);
    print(
        'assets in box total: ${zanoAssetsBox.length} ${zanoAssetsBox.values} active: ${zanoAssetsBox.values.where((element) => element.enabled).length} ${zanoAssetsBox.values.where((element) => element.enabled)}');
    for (final asset in zanoAssetsBox.values) {
      if (asset.enabled) balance[asset] = ZanoBalance(total: 0, unlocked: 0, decimalPoint: asset.decimalPoint);
    }
    await walletAddresses.init();
    await walletAddresses.updateAddress(address);

    ///balance.addAll(getZanoBalance(/**accountIndex: walletAddresses.account?.id ?? 0*/));
    //_setListeners();
    await updateTransactions();

    _autoSaveTimer = Timer.periodic(Duration(seconds: _autoSaveInterval), (_) async => await save());
  }

  String loadWallet(String path, String password) {
    print('load_wallet path $path password $password');
    final result = ApiCalls.loadWallet(path: path, password: password);
    print('load_wallet result $result');
    return result;
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
  Future<void> rescan({required int height}) async {
    walletInfo.restoreHeight = height;
    walletInfo.isRecovery = true;
    debugPrint('setRefreshFromBlockHeight height $height');
    debugPrint('rescanBlockchainAsync');
    await startSync();
    /**walletAddresses.accountList.update();*/
    await _askForUpdateTransactionHistory();
    await save();
    await walletInfo.save();
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

  Future<void> setAsRecovered() async {
    walletInfo.isRecovery = false;
    await walletInfo.save();
  }

  bool _calledOnce = false;
  int _counter = 0;

  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();
      _cachedBlockchainHeight = 0;
      _lastKnownBlockHeight = 0;
      _initialSyncHeight = 0;
      _updateSyncInfoTimer ??= Timer.periodic(Duration(milliseconds: /*1200*/ 5000), (_) async {
        /*if (isNewTransactionExist()) {
        onNewTransaction?.call();
      }*/

        final walletStatus = getWalletStatus();
        _updateSyncProgress(walletStatus);
        // You can call getWalletInfo ONLY if getWalletStatus returns NOT is in long refresh and wallet state is 2 (ready)
        if (!walletStatus.isInLongRefresh && walletStatus.walletState == 2) {
          final walletInfo = getWalletInfo();
          seed = walletInfo.wiExtended.seed;
          keys = ZanoWalletKeys(
            privateSpendKey: walletInfo.wiExtended.spendPrivateKey,
            privateViewKey: walletInfo.wiExtended.viewPrivateKey,
            publicSpendKey: walletInfo.wiExtended.spendPublicKey,
            publicViewKey: walletInfo.wiExtended.viewPublicKey,
          );

          for (final item in walletInfo.wi.balances) {
            if (item.assetInfo.ticker == 'ZANO') {
              balance[CryptoCurrency.zano] = ZanoBalance(total: item.total, unlocked: item.unlocked, decimalPoint: ZanoFormatter.defaultDecimalPoint);
            } else {
              for (final asset in balance.keys) {
                if (asset is ZanoAsset && asset.assetId == item.assetInfo.assetId) {
                  balance[asset] = ZanoBalance(total: item.total, unlocked: item.unlocked, decimalPoint: asset.decimalPoint);
                }
              }
            }
          }

          //await getAssetsWhitelist();
          if (!_calledOnce) {
            //await addAssetsWhitelist('00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff');
            //await removeAssetsWhitelist('cc4e69455e63f4a581257382191de6856c2156630b3fba0db4bdd73ffcfb36b6');
            //await removeAssetsWhitelist('bb9590162509f956ff79851fb1bc0ced6646f5d5ba7eae847a9f21c92c39437c');
            //await removeAssetsWhitelist('');
            _calledOnce = true;
          } else {
            await getAssetsWhitelist();
          }
          // if (++_counter >= 10) {
          //   await getAssetsWhitelist();
          //   _counter = 0;
          // }
        }
      });
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print(e);
      rethrow;
    }
  }

  @override
  Future<void>? updateBalance() => null;

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

  void addInitialAssets() {
    final initialZanoAssets = DefaultZanoAssets().initialZanoAssets;

    for (var token in initialZanoAssets) {
      zanoAssetsBox.put(token.assetId, token);
    }
  }

  Future<CryptoCurrency> addZanoAssetById(String assetId) async {
    if (zanoAssetsBox.containsKey(assetId)) {
      throw 'zano asset with id $assetId already added';
    }
    final assetDescriptor = await addAssetsWhitelist(assetId);
    if (assetDescriptor == null) {
      throw "there's no zano asset with id $assetId";
    }
    String? iconPath;
    try {
      iconPath = CryptoCurrency.all.firstWhere((element) => element.title.toUpperCase() == assetDescriptor.title.toUpperCase()).iconPath;
    } catch (_) {}
    final asset = ZanoAsset.copyWith(assetDescriptor, iconPath, 'ZANO', assetId: assetId, enabled: true);
    await zanoAssetsBox.put(asset.assetId, ZanoAsset.copyWith(asset, iconPath, 'ZANO'));
    balance[asset] = ZanoBalance(total: 0, unlocked: 0, decimalPoint: asset.decimalPoint);
    return asset;
  }

  Future<void> changeZanoAssetAvailability(ZanoAsset asset) async {
    String? iconPath;
    try {
      iconPath = CryptoCurrency.all.firstWhere((element) => element.title.toUpperCase() == asset.title.toUpperCase()).iconPath;
    } catch (_) {}
    await zanoAssetsBox.put(asset.assetId, ZanoAsset.copyWith(asset, iconPath, 'ZANO'));
    if (asset.enabled) {
      final assetDescriptor = await addAssetsWhitelist(asset.assetId);
      if (assetDescriptor == null) {
        throw 'error adding zano asset';
      }
      balance[asset] = ZanoBalance(total: 0, unlocked: 0, decimalPoint: asset.decimalPoint);
    } else {
      final result = await removeAssetsWhitelist(asset.assetId);
      if (result == false) {
        throw 'error removing zano asset';
      }
      balance.removeWhere((key, _) => key is ZanoAsset && key.assetId == asset.assetId);
    }
  }

  Future<void> deleteZanoAsset(ZanoAsset asset) async {
    final result = await removeAssetsWhitelist(asset.assetId);
    if (result == false) return;
    if (asset.isInBox) await asset.delete();
    balance.removeWhere((key, _) => key is ZanoAsset && key.assetId == asset.assetId);
  }

  Future<ZanoAsset?> getZanoAsset(String assetId) async {
    return await getAssetInfo(assetId);
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

  Future<void> _askForUpdateTransactionHistory() async => await updateTransactions();

  void _onNewBlock(int height, int blocksLeft, double ptc) async {
    try {
      if (walletInfo.isRecovery) {
        await _askForUpdateTransactionHistory();
        /*walletAddresses.accountList.update();*/
      }

      if (blocksLeft < 1000) {
        await _askForUpdateTransactionHistory();
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
      await Future<void>.delayed(Duration(seconds: 1)); // TODO: ???
    } catch (e) {
      print(e.toString());
    }
  }

  void _updateSyncProgress(GetWalletStatusResult walletStatus) {
    final syncHeight = walletStatus.currentWalletHeight;
    if (_initialSyncHeight <= 0) {
      _initialSyncHeight = syncHeight;
    }
    final bchHeight = walletStatus.currentDaemonHeight;

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
}
