import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';

import 'package:cw_xelis/xelis_exception.dart';
import 'package:cw_xelis/xelis_asset_balance.dart';
import 'package:cw_xelis/src/api/wallet.dart' as x_wallet;
import 'package:cw_xelis/src/api/network.dart';
import 'package:cw_xelis/src/api/utils.dart';
import 'package:cw_xelis/xelis_asset.dart';
import 'package:cw_xelis/xelis_transaction_info.dart';
import 'package:cw_xelis/xelis_transaction_history.dart';
import 'package:cw_xelis/xelis_transaction_credentials.dart';
import 'package:cw_xelis/xelis_wallet_addresses.dart';
import 'package:cw_xelis/xelis_pending_transaction.dart';
import 'package:cw_xelis/xelis_events.dart';
import 'package:cw_xelis/xelis_store_utils.dart';
import 'package:cw_core/wallet_keys_file.dart';

import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;

part 'xelis_wallet.g.dart';

class XelisWallet = XelisWalletBase with _$XelisWallet;

class Recipient {
  final String address;
  final BigInt amount;
  final bool isChange;

  Recipient({
    required this.address,
    required this.amount,
    required this.isChange,
  });
}

abstract class XelisWalletBase 
  extends WalletBase<XelisAssetBalance,
    XelisTransactionHistory, XelisTransactionInfo
> with Store, WalletKeysFile {
  final x_wallet.XelisWallet _libWallet;

  XelisWalletBase({
    required WalletInfo walletInfo,
    required x_wallet.XelisWallet libWallet,
    required String password,
    required this.network,
    required this.encryptionFileUtils,
  }) 
  : 
    _password = password,
    _libWallet = libWallet,
    _isTransactionUpdating = false,
    this.syncStatus = NotConnectedSyncStatus(),
    super(walletInfo)
  {
    isTestnet = network == Network.testnet;
    final curr = isTestnet ? CryptoCurrency.txel : CryptoCurrency.xel;
    balance = ObservableMap.of({curr: XelisAssetBalance.zero(symbol: isTestnet ? "tXEL" : "XEL")});
    walletAddresses = XelisWalletAddresses(walletInfo, _libWallet);
    transactionHistory = XelisTransactionHistory(
      walletInfo: walletInfo, 
      password: password,
      encryptionFileUtils: encryptionFileUtils
    );

    if (!CakeHive.isAdapterRegistered(XelisAsset.typeId)) {
      CakeHive.registerAdapter(XelisAssetAdapter());
    }

    _sharedPrefs.complete(SharedPreferences.getInstance());
  }

  String _password;
  final EncryptionFileUtils encryptionFileUtils;

  bool synced = false;
  bool connecting = false;
  bool requestedClose = false;
  String persistantPeer = "";
  Timer? syncTimer;
  int pruneHeight = 0;
  String _seed = "";
  Network network;

  late final Box<XelisAsset> xelAssetsBox;

  @observable
  double? estimatedFee;

  @override
  late ObservableMap<CryptoCurrency, XelisAssetBalance> balance;

  final Completer<SharedPreferences> _sharedPrefs = Completer();

  @override
  @observable
  SyncStatus syncStatus;

  @override
  late XelisWalletAddresses walletAddresses;

  @override
  bool get hasRescan => true;

  @override
  String get password => _password;

  @override
  String get seed => _seed;
  void updateSeed(String? language) async {
    _seed = await _libWallet.getSeed(languageIndex: getLanguageIndexFromStr(input: language ?? "english"));
  }

  Future<String> langSeed(String? language) async => await _libWallet.getSeed(languageIndex: getLanguageIndexFromStr(input: language ?? "english"));

  @override
  Object get keys => {};

  @override
  late final XelisTransactionHistory transactionHistory;

  bool _isTransactionUpdating;
  StreamSubscription? _eventSub;

  void _subscribeToWalletEvents() {
    _eventSub = _convertRawEvents().listen(_handleEvent);
  }

  Future<void> _unsubscribeFromWalletEvents() async {
    await _eventSub?.cancel();
    _eventSub = null;
  }

  Stream<Event> _convertRawEvents() async* {
    final stream = _libWallet.eventsStream();

    await for (final raw in stream) {
      try {
        final data = jsonDecode(raw);
        final event = xelis_sdk.WalletEvent.fromStr(data['event'] as String);

        switch (event) {
          case xelis_sdk.WalletEvent.newTransaction:
            yield NewTransaction(xelis_sdk.TransactionEntry.fromJson(data['data']));
          case xelis_sdk.WalletEvent.balanceChanged:
            yield BalanceChanged(data['data']['asset'] as String, data['data']['balance'] as int);
          case xelis_sdk.WalletEvent.newTopoHeight:
            yield NewTopoheight(data['data']['topoheight'] as int);
          case xelis_sdk.WalletEvent.rescan:
            yield Rescan(data['data']['start_topoheight'] as int);
          case xelis_sdk.WalletEvent.online:
            yield const Online();
          case xelis_sdk.WalletEvent.offline:
            yield const Offline();
          case xelis_sdk.WalletEvent.historySynced:
            yield HistorySynced(data['data']['topoheight'] as int);
          case xelis_sdk.WalletEvent.newAsset:
            yield NewAsset(
              data['data']['asset'] as String,
              data['data']['decimals'] as int,
              data['data']['max_supply'] as int,
              data['data']['name'] as String,
              data['data']['owner'] as String?,
              data['data']['ticker'] as String,
              data['data']['topoheight'] as int,
            );
          default:
            continue;
        }
      } catch (e) {
        printV('Failed to parse wallet event: $e');
      }
    }
  }

  @override
  Future<void> save() async {
    await saveXelisNetwork(name, network);
    if (!(await WalletKeysFile.hasKeysFile(walletInfo.name, walletInfo.type))) {
      await saveKeysFile(_password, encryptionFileUtils);
      saveKeysFile(_password, encryptionFileUtils, true);
    }

    await walletAddresses.updateAddressesInBox();
    final path = await makePath();
    await encryptionFileUtils.write(path: path, password: _password, data: toJSON());
    await transactionHistory.save();
  }

  @override
  WalletKeysData get walletKeysData => WalletKeysData(
    mnemonic: _seed,
    privateKey: "",
    passphrase: "",
  );

  String toJSON() => json.encode({
    'mnemonic': _seed,
    'private_key': privateKey,
    'balance': balance[currency]!.toJSON(),
    'passphrase': passphrase,
  });

  @action
  @override
  Future<void> startSync() async {
    try {
      if (!(await _libWallet.isOnline())) { return; }
      syncStatus = AttemptingSyncStatus();
      await _fetchPruneHeight();
      await updateBalance();
      await _updateTransactions();
      syncStatus = SyncedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    if (connecting) {
      return;
    }
    connecting = true;
    String addr = "us-node.xelis.io";
    if (node.uri.host != addr) {
      addr = node.uri.host;
      if (node.uri.port != "") {
        addr += ":" + node.uri.port.toString();
      }
    }
    if (addr != persistantPeer) {
      if (syncTimer != null) {
        syncTimer!.cancel();
        syncTimer = null;
      }
      persistantPeer = addr;
    }
    if (await _libWallet.isOnline()) {
      await _libWallet.offlineMode();
    }
    await _libWallet.onlineMode(daemonAddress: addr);
    await this.startSync();
    connecting = false;
  }

  @override
  Future<void> rescan({required int height}) async {
    walletInfo.restoreHeight = height;
    walletInfo.isRecovery = true;
    syncStatus = AttemptingSyncStatus();
    await _libWallet.rescan(topoheight: BigInt.from(pruneHeight > height ? pruneHeight : height));
    await walletInfo.save();
    syncStatus = SyncedSyncStatus();
  }

  Future<void> _handleEvent(Event event) async {
    switch (event) {
      case NewTransaction():
        transactionHistory.addOne(
          await XelisTransactionInfo.fromTransactionEntry(event.tx, wallet: _libWallet),
        );
        await updateBalance();
        break;

      case BalanceChanged():
        if (event.asset == xelis_sdk.xelisAsset) {
          final curr = isTestnet ? CryptoCurrency.txel : CryptoCurrency.xel;

          balance[curr] = XelisAssetBalance(
            balance: event.balance,
            decimals: 8,
          );
        } else {
          final curr = findTrackedAssetById(event.asset);
          
          if (curr != null) {
            balance[curr] = XelisAssetBalance(
              balance: event.balance,
              decimals: curr.decimals,
              symbol: curr.symbol,
            );
          }
        }
        break;

      case NewTopoheight():
        // maybe track height
        break;

      case Online():
        syncStatus = ConnectedSyncStatus();
        break;

      case Offline():
        syncStatus = NotConnectedSyncStatus();
        break;

      case HistorySynced():
        // optional
        break;

      case Rescan():
        // optional
        break;
      
      case NewAsset():
        if (event.asset == xelis_sdk.xelisAsset) {
          break;
        } 
        final newAsset = XelisAsset(
          name: event.name,
          symbol: event.ticker,
          id: event.asset,
          decimals: event.decimals,
          enabled: false,
        );
        await addAsset(newAsset);
        break;
    }
  }

  Future<void> _fetchPruneHeight() async {
    final infoString = await _libWallet.getDaemonInfo();
    final Map<String, dynamic> nodeInfo =
        (json.decode(infoString) as Map).cast();

    pruneHeight = int.tryParse(nodeInfo['pruned_topoheight']?.toString() ?? '0') ?? 0;
  }

  @action
  Future<void> init() async {
    try {
      final boxName = "${walletInfo.name.replaceAll(" ", "_")}_${XelisAsset.boxName}";
      xelAssetsBox = await CakeHive.openBox<XelisAsset>(boxName);
  
      walletAddresses.init();
      await transactionHistory.init();
      await _fetchAssets();
      _subscribeToWalletEvents();
      _seed = await _libWallet.getSeed();
      await save();
    } catch (e) {
      printV("Failed to init wallet: $e");
    }
  }

  XelisAsset? findTrackedAssetById(String assetId) {
    try {
      return xelAssetsBox.values.firstWhere((asset) => asset.id == assetId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> changePassword(String password) async {
    return () async {
      await _libWallet.changePassword(oldPassword: _password, newPassword: password);
      _password = password;
    }();
  }

  Future<void> _fetchAssetBalances() async {
    for (var asset in xelAssetsBox.values) {
      if (asset.enabled) {
        try {
          final res = await _libWallet.getAssetBalanceByIdRaw(asset: asset.id);
          final assetBalance = XelisAssetBalance(balance: res.toInt(), asset: asset.id, symbol: asset.symbol, decimals: asset.decimals);
          balance[asset] = assetBalance;
        } catch (e) {
          printV('Error fetching Xelis Asset (${asset.symbol}) balance ${e.toString()}');
          final assetBalance = balance[asset] ??
              XelisAssetBalance(balance: 0, asset: asset.id, symbol: asset.symbol, decimals: asset.decimals);
          balance[asset] = assetBalance;
        }
      } else {
        balance.remove(asset);
      }
    }
  }

  List<XelisAsset> get xelAssets => xelAssetsBox.values.toList();

  Future<void> _fetchAssets() async {
    final bal = await _libWallet.getAssetBalancesRaw();

    for (final entry in bal.entries) {
      final assetId = entry.key;
      if (assetId == xelis_sdk.xelisAsset) { continue; }

      final amount = entry.value;

      final existing = xelAssetsBox.values
          .cast<XelisAsset?>()
          .firstWhere((e) => e?.id == assetId, orElse: () => null);

      final metadata = await _libWallet.getAssetMetadata(asset: assetId);

      final merged = XelisAsset(
        name: metadata.name,
        symbol: metadata.ticker,
        id: assetId,
        decimals: metadata.decimals,
        enabled: existing?.enabled ?? false,
      );

      await xelAssetsBox.put(assetId, merged);

      balance[merged] = XelisAssetBalance(
        balance: amount.toInt(),
        asset: merged.id,
        symbol: merged.symbol,
        decimals: merged.decimals,
      );
    }
  }

  Future<void> addAsset(XelisAsset asset) async {
    await xelAssetsBox.put(asset.id, asset);
    if (asset.enabled) {
      try {
        final assetBalance = (await _libWallet.getAssetBalanceByIdRaw(asset: asset.id)).toInt();
        balance[asset] = XelisAssetBalance(balance: assetBalance, asset: asset.id, symbol: asset.symbol, decimals: asset.decimals);
      } catch (_) {
        balance[asset] = balance[asset] ??
          XelisAssetBalance(balance: 0, asset: asset.id, symbol: asset.symbol, decimals: asset.decimals);
      }

    } else {
      balance.remove(asset);
    }
  }

  Future<void> deleteAsset(XelisAsset asset) async {
    await asset.delete();

    balance.remove(asset);
    await _removeTokenTransactionsInHistory(asset);
    await updateBalance();
  }

  Future<void> _removeTokenTransactionsInHistory(XelisAsset asset) async {
    transactionHistory.transactions.removeWhere((key, value) => value.assetIds[0] == asset.id && value.assetIds.length == 1);
    await transactionHistory.save();
  }

  Future<XelisAsset?> getAsset(String id) async {
    try {
      final metadata = await _libWallet.getAssetMetadata(asset: id);
      
      return XelisAsset(
        name: metadata.name,
        symbol: metadata.ticker,
        id: id,
        decimals: metadata.decimals
      );
    } catch (e, s) {
      printV('Error fetching asset: ${e.toString()}, ${s.toString()}');
      return null;
    }
  }


  @override
  Future<void> updateBalance() async {
    var curr = isTestnet ? CryptoCurrency.txel : CryptoCurrency.xel;
    balance[curr] = XelisAssetBalance(
      balance: (await _libWallet.getXelisBalanceRaw()).toInt(),
      decimals: 8
    );
    await _fetchAssetBalances();
    await save();
  }

  Future<int> _liveFeeEstimate(Object credentials, {String? assetId}) async {
    final xelisCredentials = credentials as XelisTransactionCredentials;

    final outputs = xelisCredentials.outputs;
    final asset = assetId ?? xelis_sdk.xelisAsset;

    final defaultFee = 0.00025;

    // Use default address if recipients list is empty to ensure basic fee estimates are readily available
    final effectiveRecipients = xelisCredentials.outputs.isNotEmpty
      ? xelisCredentials.outputs.map((output) {
        final address = output.isParsedAddress
          ? output.extractedAddress!
          : output.address;

        return XelisTxRecipient (
          address: address,
          amount: output.cryptoAmount ?? '0.0',
          isChange: false,
        );
      }).toList()
      : [
          XelisTxRecipient (
            address: 'xel:xz9574c80c4xegnvurazpmxhw5dlg2n0g9qm60uwgt75uqyx3pcsqzzra9m',
            amount: '1.0',
            isChange: false,
          ),
        ];

    try {
      final transfers = await Future.wait(
        effectiveRecipients.map((recipient) async {
          return x_wallet.Transfer(
            floatAmount: double.parse(recipient.amount),
            strAddress: recipient.address,
            assetHash: asset,
            extraData: null,
          );
        }),
      );

      final liveFee = double.parse(
        await _libWallet.estimateFees(transfers: transfers),
      );
      final rawFee = (liveFee * pow(10, 8)).round();
      estimatedFee = liveFee;
      return rawFee.toInt();
    } catch (e, s) {
      printV("Fee estimation failed. Using fallback fee: $defaultFee. error: $e, stackTrace: $s");
      estimatedFee = 0.00025;
      return (defaultFee * pow(10, 8)).round().toInt();
    }
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    final asset = xelis_sdk.xelisAsset;

    // Default values
    final defaultDecimals = 8;
    final defaultFee = 25000;

    final effectiveRecipients = [
      Recipient(
        address: 'xel:xz9574c80c4xegnvurazpmxhw5dlg2n0g9qm60uwgt75uqyx3pcsqzzra9m',
        amount: BigInt.from(amount ?? 0),
        isChange: false,
      ),
    ];

    // FIXME: hardcoded
    return defaultFee;
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final xelisCredentials = credentials as XelisTransactionCredentials;

    final outputs = xelisCredentials.outputs;

    final hasMultiDestination = outputs.length > 1;
    if (outputs.length > 255) {
      throw XelisTooManyOutputsException(outputs.length);
    }

    final CryptoCurrency transactionCurrency =
        balance.keys.firstWhere((element) => element == xelisCredentials.currency);

    final asset = balance[transactionCurrency]!.asset;
    final walletBalanceForCurrency = balance[transactionCurrency]!.balance;
    var totalAmountFromCredentials = 0;

    final fee = await _liveFeeEstimate(credentials, assetId: asset);

    double totalAmount = 0.0;
    bool shouldSendAll = false;
    if (hasMultiDestination) {
      if (outputs.any((item) => item.sendAll || (item.formattedCryptoAmount ?? 0) < 0)) {
        throw XelisTransactionCreationException(transactionCurrency);
      }

      totalAmountFromCredentials =
          outputs.fold(0, (acc, value) => acc + (value.formattedCryptoAmount ?? 0));

      totalAmount = double.parse(await _libWallet.formatCoin(
        atomicAmount: BigInt.from(totalAmountFromCredentials),
        assetHash: asset,
      ));

      if (walletBalanceForCurrency < totalAmount) {
        throw XelisTransactionCreationException(transactionCurrency);
      }
    } else {
      final output = outputs.first;
      shouldSendAll = output.sendAll;

      if (!shouldSendAll) {
        totalAmount = double.parse(output.cryptoAmount ?? '0.0');
      } else {
        totalAmountFromCredentials = balance[transactionCurrency]!.balance;
      }

      if (walletBalanceForCurrency < totalAmount || totalAmount < 0) {
        throw XelisTransactionCreationException(transactionCurrency);
      }
    }

    var feeCurrency = isTestnet ? CryptoCurrency.txel : CryptoCurrency.xel;
    bool isSendingXelis = true;
    if (transactionCurrency != feeCurrency) {
      isSendingXelis = false;
    }

    if (isSendingXelis) {
      if (balance[feeCurrency]!.balance < (totalAmount + fee)) {
        throw XelisTransactionCreationException(transactionCurrency);
      }
    } else {
      if (balance[feeCurrency]!.balance < fee) {
        throw XelisTransactionCreationException(feeCurrency);
      }
    }

    late final String txJson;
    if (shouldSendAll) {
      txJson = await _libWallet.createTransferAllTransaction(
        strAddress: xelisCredentials.outputs.first.isParsedAddress
          ? xelisCredentials.outputs.first.extractedAddress!
          : xelisCredentials.outputs.first.address,
        assetHash: asset,
        extraData: null,
      );
    } else {
      txJson = await _libWallet.createTransfersTransaction(
        transfers: xelisCredentials.outputs.map((output) {
          final amount = double.parse(output.cryptoAmount ?? '0.0');

          return x_wallet.Transfer(
            floatAmount: amount,
            strAddress: output.isParsedAddress
              ? output.extractedAddress!
              : output.address,
            assetHash: asset,
            extraData: null,
          );
        }).toList(),
      );
    }


    final txMap = jsonDecode(txJson);
    final txHash = txMap['hash'] as String;

    // Broadcast the transaction
    final send = () async {
      await _libWallet.broadcastTransaction(txHash: txHash);
      await updateBalance();
    };

    return XelisPendingTransaction(
      txid: txHash,
      amount: totalAmountFromCredentials,
      fee: txMap['fee'] as int,
      decimals: balance[transactionCurrency]!.decimals,
      send: send
    );
  }

  // TODO
  @override
  Future<String> signMessage(String message, {String? address}) async {
    throw UnimplementedError();
  }

  // TODO
  @override
  Future<bool> verifyMessage(String message, String signature, {String? address}) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, XelisTransactionInfo>> fetchTransactions() async {
    final txList = (await _libWallet.allHistory())
        .map((jsonStr) => xelis_sdk.TransactionEntry.fromJson(
            json.decode(jsonStr),
          ) as xelis_sdk.TransactionEntry)
        .toList();

    final Map<String, XelisTransactionInfo> result = {};

    for (var entry in txList) {
      result[entry.hash] = await XelisTransactionInfo.fromTransactionEntry(entry, wallet: _libWallet);
    }

    return result;
  }

  Future<void> _updateTransactions({bool? isRescan}) async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      if (!await _libWallet.isOnline()) {
        return;
      }

      _isTransactionUpdating = true;

      final transactions = await fetchTransactions();

      if (isRescan == true) {
        transactionHistory.clear();
        transactionHistory.addMany(transactions);
      } else {
        transactionHistory.update(transactions);
      }
      await transactionHistory.save();
      _isTransactionUpdating = false;
    } catch (_) {
      _isTransactionUpdating = false;
    }
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    throw UnimplementedError();
  }

  @action
  Future<void> goOnline(String daemon) async {
    await _libWallet.onlineMode(daemonAddress: daemon);
  }

  @action
  Future<void> goOffline() async {
    await _libWallet.offlineMode();
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    if (requestedClose) {
      return;
    }
    requestedClose = true;
    await _unsubscribeFromWalletEvents();
    await _libWallet.offlineMode();
    await _libWallet.close();
    x_wallet.dropWallet(wallet: _libWallet);
  }
}