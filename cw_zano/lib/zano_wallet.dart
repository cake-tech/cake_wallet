import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/monero_wallet_utils.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_zano/api/model/balance.dart';
import 'package:cw_zano/api/model/create_wallet_result.dart';
import 'package:cw_zano/api/model/destination.dart';
import 'package:cw_zano/api/model/get_recent_txs_and_info_result.dart';
import 'package:cw_zano/api/model/get_wallet_status_result.dart';
import 'package:cw_zano/api/model/subtransfer.dart';
import 'package:cw_zano/api/model/transfer.dart';
import 'package:cw_zano/model/pending_zano_transaction.dart';
import 'package:cw_zano/model/zano_asset.dart';
import 'package:cw_zano/model/zano_balance.dart';
import 'package:cw_zano/model/zano_transaction_creation_exception.dart';
import 'package:cw_zano/model/zano_transaction_credentials.dart';
import 'package:cw_zano/model/zano_transaction_info.dart';
import 'package:cw_zano/model/zano_wallet_keys.dart';
import 'package:cw_zano/zano_formatter.dart';
import 'package:cw_zano/zano_transaction_history.dart';
import 'package:cw_zano/zano_wallet_addresses.dart';
import 'package:cw_zano/zano_wallet_api.dart';
import 'package:cw_zano/zano_wallet_exceptions.dart';
import 'package:cw_zano/zano_wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:collection/collection.dart';

part 'zano_wallet.g.dart';

class ZanoWallet = ZanoWalletBase with _$ZanoWallet;

abstract class ZanoWalletBase extends WalletBase<ZanoBalance, ZanoTransactionHistory, ZanoTransactionInfo> with Store, ZanoWalletApi {
  static const int _autoSaveInterval = 30;

  //List<Transfer> transfers = [];
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
  /*
  late final Box<ZanoAsset> zanoAssetsBox;
  List<ZanoAsset> whitelists = [];
  List<ZanoAsset> get zanoAssets => zanoAssetsBox.values.toList();
  */
  Map<String, ZanoAsset> zanoAssets = {};

  //zano_wallet.SyncListener? _listener;
  // ReactionDisposer? _onAccountChangeReaction;
  Timer? _updateSyncInfoTimer;

  int _cachedBlockchainHeight = 0;
  int _lastKnownBlockHeight = 0;
  int _initialSyncHeight = 0;
  int currentDaemonHeight = 0;
  bool _isTransactionUpdating;
  bool _hasSyncAfterStartup;
  Timer? _autoSaveTimer;

  /// index of last transaction fetched
  int _lastTxIndex = 0;
  /// number of transactions in each request
  static const int _txChunkSize = 30;

  ZanoWalletBase(WalletInfo walletInfo)
      : balance = ObservableMap.of({CryptoCurrency.zano: ZanoBalance.empty()}),
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

  static Future<ZanoWallet> create({required WalletCredentials credentials}) async {
    final wallet = ZanoWallet(credentials.walletInfo!);
    await wallet.connectToNode(node: Node());
    final path = await pathForWallet(name: credentials.name, type: credentials.walletInfo!.type);
    final createWalletResult = await wallet.createWallet(path, credentials.password!);
    await _parseCreateWalletResult(createWalletResult, wallet);
    //await wallet.store(); // TODO: unnecessary here?
    await wallet.init(createWalletResult.wi.address);
    return wallet;
  }

  static Future<ZanoWallet> restore({required ZanoRestoreWalletFromSeedCredentials credentials}) async {
    final wallet = ZanoWallet(credentials.walletInfo!);
    await wallet.connectToNode(node: Node());
    final path = await pathForWallet(name: credentials.name, type: credentials.walletInfo!.type);
    final createWalletResult = await wallet.restoreWalletFromSeed(path, credentials.password!, credentials.mnemonic);
    await _parseCreateWalletResult(createWalletResult, wallet);
    //await wallet.store(); // TODO: unnecessary here?
    await wallet.init(createWalletResult.wi.address);
    return wallet;
  }

  static Future<ZanoWallet> open({required String name, required String password, required WalletInfo walletInfo}) async {
    final path = await pathForWallet(name: name, type: walletInfo.type);
    final wallet = ZanoWallet(walletInfo);
    await wallet.connectToNode(node: Node());
    final createWalletResult = await wallet.loadWallet(path, password);
    await _parseCreateWalletResult(createWalletResult, wallet);
    //await wallet.store(); // TODO: unnecessary here?
    await wallet.init(createWalletResult.wi.address);
    return wallet;
  }

  static Future<void> _parseCreateWalletResult(CreateWalletResult result, ZanoWallet wallet) async {
    wallet.hWallet = result.walletId;
    _info('setting hWallet = ${result.walletId}');
    wallet.walletAddresses.address = result.wi.address;
    for (final item in result.wi.balances) {
      if (item.assetInfo.assetId == zanoAssetId) {
        wallet.balance[CryptoCurrency.zano] = ZanoBalance(
          total: item.total,
          unlocked: item.unlocked,
        );
      }
    }
    if (result.recentHistory.history != null) {
      final transfers = result.recentHistory.history!;
      final transactions = Transfer.makeMap(transfers, wallet.zanoAssets, wallet.currentDaemonHeight);
      wallet.transactionHistory.addMany(transactions);
      await wallet.transactionHistory.save();
    }
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
      final transfers = <Transfer>[];
      late GetRecentTxsAndInfoResult result;
      bool first = true;
      do {
        result = await getRecentTxsAndInfo(offset: _lastTxIndex, count: _txChunkSize);
        // TODO: remove this, just for debug purposes
        if (first && result.transfers.isEmpty) return {};
        first = false;
        _lastTxIndex += result.transfers.length;
        transfers.addAll(result.transfers);
      } while (result.lastItemIndex + 1 < result.totalTransfers);
      return Transfer.makeMap(transfers, zanoAssets, currentDaemonHeight);
    } catch (e) {
      print(e);
      return {};
    }
  }

  Future<void> init(String address) async {
    final boxName = '${walletInfo.name.replaceAll(' ', '_')}_${ZanoAsset.zanoAssetsBoxName}';
    /*zanoAssetsBox = await CakeHive.openBox<ZanoAsset>(boxName);
    print(
        'assets in box total: ${zanoAssetsBox.length} ${zanoAssetsBox.values} active: ${zanoAssetsBox.values.where((element) => element.enabled).length} ${zanoAssetsBox.values.where((element) => element.enabled)}');
    for (final asset in zanoAssetsBox.values) {
      if (asset.enabled) balance[asset] = ZanoBalance.empty(decimalPoint: asset.decimalPoint);
    }*/
    await walletAddresses.init();
    await walletAddresses.updateAddress(address);
    //_setListeners();
    await updateTransactions();
    _autoSaveTimer = Timer.periodic(Duration(seconds: _autoSaveInterval), (_) async => await save());
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
  Future<void> rescan({required int height}) => throw UnimplementedError();
  /*@override
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
  }*/

  @override
  Future<void> save() async {
    try {
      await store();
      await walletAddresses.updateAddressesInBox();
    } catch (e) {
      print('Error while saving Zano wallet file ${e.toString()}');
    }
  }

  int _counter = 0;
  bool _sent = false;

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

        final walletStatus = await getWalletStatus();
        currentDaemonHeight = walletStatus.currentDaemonHeight;
        _updateSyncProgress(walletStatus);

        // we can call getWalletInfo ONLY if getWalletStatus returns NOT is in long refresh and wallet state is 2 (ready)
        if (!walletStatus.isInLongRefresh && walletStatus.walletState == 2) {
          final walletInfo = await getWalletInfo();
          seed = walletInfo.wiExtended.seed;
          keys = ZanoWalletKeys(
            privateSpendKey: walletInfo.wiExtended.spendPrivateKey,
            privateViewKey: walletInfo.wiExtended.viewPrivateKey,
            publicSpendKey: walletInfo.wiExtended.spendPublicKey,
            publicViewKey: walletInfo.wiExtended.viewPublicKey,
          );

          /*bool areSetsEqual<T>(Set<T> set1, Set<T> set2) => set1.length == set2.length && set1.every(set2.contains);

          Set<String> getSetFromWhitelist(List<ZanoAsset> whitelist, bool isInGlobalWhitelist) =>
              whitelist.where((item) => item.isInGlobalWhitelist == isInGlobalWhitelist).map((item) => item.assetId).toSet();
          bool areWhitelistsTheSame(List<ZanoAsset> whitelist1, List<ZanoAsset> whitelist2) {
            return areSetsEqual(getSetFromWhitelist(whitelist1, true), getSetFromWhitelist(whitelist2, true)) &&
                areSetsEqual(getSetFromWhitelist(whitelist1, false), getSetFromWhitelist(whitelist2, false));
          }*/

          /*void addOrUpdateBalance(ZanoAsset asset, Balance? _balance) {
            if (balance.keys.any((element) => element is ZanoAsset && element.assetId == asset.assetId)) {
              balance[balance.keys.firstWhere((element) => element is ZanoAsset && element.assetId == asset.assetId)] = _balance == null
                  ? ZanoBalance.empty(decimalPoint: asset.decimalPoint)
                  : ZanoBalance(total: _balance.total, unlocked: _balance.unlocked, decimalPoint: asset.decimalPoint);
            } else {
              balance[asset] = _balance == null
                  ? ZanoBalance.empty(decimalPoint: asset.decimalPoint)
                  : ZanoBalance(total: _balance.total, unlocked: _balance.unlocked, decimalPoint: asset.decimalPoint);
            }
          }*/

          /*final whitelistsFromServer = await getAssetsWhitelist();
          void loadWhitelists() {
            debugPrint('loadWhitelists');
            final globalWhitelist = whitelistsFromServer.where((item) => item.isInGlobalWhitelist);
            final globalWhitelistIds = globalWhitelist.map((item) => item.assetId).toSet();
            final localWhitelist = whitelistsFromServer.where((item) => !item.isInGlobalWhitelist && !globalWhitelistIds.contains(item.assetId));
            for (final asset in globalWhitelist.followedBy(localWhitelist)) {
              // we have two options:
              // 1. adding as active (enabled) and adding to balance (even there's no balance for this asset)
              // 2. checking if there's a balance, then setting enabled true or false
              bool firstOption = 1 == 0;
              if (firstOption) {
                asset.enabled = true;
                zanoAssetsBox.put(asset.assetId, ZanoAsset.copyWith(asset, _getIconPath(asset.title), enabled: true));
                addOrUpdateBalance(asset, walletInfo.wi.balances.firstWhereOrNull((item) => item.assetId == asset.assetId));
              } else {
                final _balance = walletInfo.wi.balances.firstWhereOrNull((item) => item.assetId == asset.assetId);
                zanoAssetsBox.put(asset.assetId, ZanoAsset.copyWith(asset, _getIconPath(asset.title), enabled: _balance != null));
                addOrUpdateBalance(asset, _balance);
              }
            }
          }

          if (this.whitelists.isEmpty) {
            if (zanoAssetsBox.isEmpty) loadWhitelists();
            this.whitelists = whitelistsFromServer;
          } else if (!areWhitelistsTheSame(whitelistsFromServer, this.whitelists)) {
            // // updating whitelists from server
            // if (zanoAssetsBox.isEmpty) {
            //   debugPrint('first loading of whitelists');
            //   loadWhitelists();
            // } else {
            //   debugPrint('later updating of whitelists');
            // }
            debugPrint('whitelists changed!');
            if (zanoAssetsBox.isEmpty) loadWhitelists();
            this.whitelists = whitelistsFromServer;
          }
          // TODO: here should be synchronization of whitelists
          // for (final item in whitelists) {
          //   if (!zanoAssets.containsKey(item.assetId)) zanoAssets[item.assetId] = item;
          // }
          // // removing assets missing in whitelists (in case some were removed since last time)
          // zanoAssets.removeWhere((key, _) => !whitelists.any((element) => element.assetId == key));

          for (final asset in balance.keys) {
            if (asset == CryptoCurrency.zano) {
              final _balance = walletInfo.wi.balances.firstWhere((element) => element.assetId == zanoAssetId);
              balance[asset] = ZanoBalance(total: _balance.total, unlocked: _balance.unlocked);
            } else if (asset is ZanoAsset) {
              addOrUpdateBalance(asset, walletInfo.wi.balances.firstWhereOrNull((element) => element.assetId == asset.assetId));
            }
          }
          */

          final assets = await getAssetsWhitelist();
          zanoAssets = {};
          for (final asset in assets) {
            final newAsset = ZanoAsset.copyWith(asset,
                icon: _getIconPath(asset.title), enabled: walletInfo.wi.balances.any((element) => element.assetId == asset.assetId));
            zanoAssets.putIfAbsent(asset.assetId, () => newAsset);
          }
          // matching balances and whitelists
          // 1. show only balances available in whitelists
          // 2. set whitelists available in balances as 'enabled' ('disabled' by default)
          for (final b in walletInfo.wi.balances) {
            if (b.assetId == zanoAssetId) {
              balance[CryptoCurrency.zano] = ZanoBalance(total: b.total, unlocked: b.unlocked);
            } else {
              final asset = zanoAssets[b.assetId];
              if (asset == null) {
                debugPrint('balance for an unknown asset ${b.assetInfo.assetId}');
                continue;
              }
              if (balance.keys.any((element) => element is ZanoAsset && element.assetId == b.assetInfo.assetId)) {
                balance[balance.keys.firstWhere((element) => element is ZanoAsset && element.assetId == b.assetInfo.assetId)] =
                    ZanoBalance(total: b.total, unlocked: b.unlocked, decimalPoint: asset.decimalPoint);
              } else {
                balance[asset] = ZanoBalance(total: b.total, unlocked: b.unlocked, decimalPoint: asset.decimalPoint);
              }
            }
          }
          // removing balances for assets missing in wallet info balances (in case they were removed for some reason)
          balance.removeWhere(
            (key, _) => key != CryptoCurrency.zano && !walletInfo.wi.balances.any((element) => element.assetId == (key as ZanoAsset).assetId),
          );

          if (_counter++ % 10 == 0 && !_sent) {
            final fee = BigInt.from(calculateEstimatedFee(MoneroTransactionPriority.fastest));
            final leo8 = 'ZxD9oVwGwW6ULix9Pqttnr7JDpaoLvDVA1KJ9eA9KRxPMRZT5X7WwtU94XH1Z6q6XTMxNbHmbV2xfZ429XxV6fST2DxEg4BQV';
            final ct = 'cc4e69455e63f4a581257382191de6856c2156630b3fba0db4bdd73ffcfb36b6';
            final test = '62af227aa643dd10a71c7f00a9d873006c0c0de3d59196e8c64cec0810bd874a';
            final bbq = 'bb9590162509f956ff79851fb1bc0ced6646f5d5ba7eae847a9f21c92c39437c';
            final destinations = <Destination>[
              Destination(amount: BigInt.from(55.6677 * pow(10, 12)), address: leo8, assetId: ct),
              Destination(amount: BigInt.from(555 * pow(10, 10)), address: leo8, assetId: test),
              Destination(amount: BigInt.from(111 * pow(10, 10)), address: leo8, assetId: bbq),
              Destination(amount: BigInt.from(333 * pow(10, 12)), address: leo8, assetId: zanoAssetId),
            ];
            //await transfer(destinations, fee, 'new 4 destinations');
            _sent = true;
          }
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

  Future<CryptoCurrency> addZanoAssetById(String assetId) async {
    if (zanoAssets.containsKey(assetId)) {
      throw ZanoWalletException('zano asset with id $assetId already added');
    }
    final assetDescriptor = await addAssetsWhitelist(assetId);
    if (assetDescriptor == null) {
      throw ZanoWalletException("there's no zano asset with id $assetId");
    }
    final asset = ZanoAsset.copyWith(assetDescriptor, icon: _getIconPath(assetDescriptor.title), assetId: assetId, enabled: true);
    zanoAssets[asset.assetId] = asset;
    balance[asset] = ZanoBalance.empty(decimalPoint: asset.decimalPoint);
    return asset;
  }

  String? _getIconPath(String title) {
    try {
      return CryptoCurrency.all.firstWhere((element) => element.title.toUpperCase() == title.toUpperCase()).iconPath;
    } catch (_) {}
    return null;
  }

  Future<void> changeZanoAssetAvailability(ZanoAsset asset) async {
    if (asset.enabled) {
      final assetDescriptor = await addAssetsWhitelist(asset.assetId);
      if (assetDescriptor == null) {
        print('error adding zano asset');
      }
      //balance[asset] = ZanoBalance.empty(decimalPoint: asset.decimalPoint);
    } else {
      final result = await removeAssetsWhitelist(asset.assetId);
      if (result == false) {
        print('error removing zano asset');
      }
      //balance.removeWhere((key, _) => key is ZanoAsset && key.assetId == asset.assetId);
    }
  }

  Future<void> deleteZanoAsset(ZanoAsset asset) async {
    final result = await removeAssetsWhitelist(asset.assetId);
    //if (result == false) return;
    //if (asset.isInBox) await asset.delete();
    //balance.removeWhere((key, _) => key is ZanoAsset && key.assetId == asset.assetId);
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
      if (blocksLeft < 1000) {
        // TODO: we can't update transactions history before loading all balances and whitelists
        await _askForUpdateTransactionHistory();
        /*walletAddresses.accountList.update();*/
        syncStatus = SyncedSyncStatus();

        if (!_hasSyncAfterStartup) {
          _hasSyncAfterStartup = true;
          await save();
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

  static void _info(String s) {
    debugPrint('[info] $s');
  }
}
