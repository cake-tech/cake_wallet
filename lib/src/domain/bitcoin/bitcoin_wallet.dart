import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/pending_transaction.dart';
import 'package:cake_wallet/src/domain/common/transaction_creation_credentials.dart';
import 'package:cake_wallet/src/domain/common/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/src/observables/observable.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/src/domain/common/wallet_info.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/bitcoin/bitcoin_transaction_history.dart';

class BitcoinWallet extends Wallet {
  BitcoinWallet({this.walletInfoSource, this.walletInfo}) {
    _syncStatus = BehaviorSubject<SyncStatus>();
    _name = BehaviorSubject<String>();
    _address = BehaviorSubject<String>();

    progressChannel.setMessageHandler((String message) async {
      print('Downloaded $message %');
      return null;
    });
  }

  static const bitcoinWalletChannel = MethodChannel('com.cakewallet.cake_wallet/bitcoin-wallet');
  static const progressChannel =
  BasicMessageChannel('progress_change', StringCodec());

  static Future<BitcoinWallet> createdWallet(
      {Box<WalletInfo> walletInfoSource,
        String name,
        bool isRecovery = false,
        int restoreHeight = 0}) async {
    const type = WalletType.bitcoin;
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

  static Future<BitcoinWallet> load(
      Box<WalletInfo> walletInfoSource, String name, WalletType type) async {
    final id = walletTypeToString(type).toLowerCase() + '_' + name;
    final walletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == id, orElse: () => null);
    return await configured(
        walletInfoSource: walletInfoSource, walletInfo: walletInfo);
  }

  static Future<BitcoinWallet> configured(
      {@required Box<WalletInfo> walletInfoSource,
       @required WalletInfo walletInfo}) async {
    final wallet = BitcoinWallet(
        walletInfoSource: walletInfoSource, walletInfo: walletInfo);

    return wallet;
  }

  @override
  String get address => _address.value;

  @override
  String get name => _name.value;

  @override
  Observable<String> get onAddressChange => _address.stream;

  @override
  Observable<String> get onNameChange => _name.stream;

  @override
  Observable<SyncStatus> get syncStatus => _syncStatus.stream;

  Box<WalletInfo> walletInfoSource;
  WalletInfo walletInfo;
  BehaviorSubject<SyncStatus> _syncStatus;
  BehaviorSubject<String> _name;
  BehaviorSubject<String> _address;

  TransactionHistory _cachedTransactionHistory;

  @override
  Future close() async {
    await bitcoinWalletChannel.invokeMethod<void>('close');
    await _name.close();
    await _address.close();
  }

  @override
  Future connectToNode({Node node, bool useSSL = false, bool isLightWallet = false}) async {
    try {
      _syncStatus.value = ConnectingSyncStatus();
      await bitcoinWalletChannel.invokeMethod<void>('connectToNode');
      _syncStatus.value = ConnectedSyncStatus();
    } catch (e) {
      _syncStatus.value = FailedSyncStatus();
      print(e);
    }
  }

  @override
  Future<PendingTransaction> createTransaction(TransactionCreationCredentials credentials) {
    // TODO: implement createTransaction
    return null;
  }

  @override
  Future<String> getAddress() async =>
      await bitcoinWalletChannel.invokeMethod<String>('getAddress');

  @override
  Future<int> getCurrentHeight() {
    // TODO: implement getCurrentHeight
    return null;
  }

  @override
  Future<String> getFilename() async =>
      await bitcoinWalletChannel.invokeMethod<String>('getFileName');

  @override
  Future<String> getFullBalance() async {
    // TODO: implement getFullBalance
    return '0';
  }

  @override
  TransactionHistory getHistory() {
    if (_cachedTransactionHistory == null) {
      _cachedTransactionHistory = BitcoinTransactionHistory();
    }

    return _cachedTransactionHistory;
  }

  Future askForUpdateTransactionHistory() async => await getHistory().update();

  @override
  Future<Map<String, String>> getKeys() async {
    final privateKey = await bitcoinWalletChannel.invokeMethod<String>("getPrivateKey");
    final keys = {"privateKey" : privateKey};
    return keys;
  }

  @override
  Future<String> getName() async => walletInfo.name;

  @override
  Future<int> getNodeHeight() {
    // TODO: implement getNodeHeight
    return null;
  }

  @override
  Future<String> getSeed() async {
    final seedList = await bitcoinWalletChannel.invokeMethod<List>("getSeed");
    String seed = '';
    for (final elem in seedList) {
      seed += elem.toString() + " ";
    }
    return seed;
  }

  @override
  WalletType getType() => WalletType.bitcoin;

  @override
  Future<String> getUnlockedBalance() async {
    // TODO: implement getUnlockedBalance
    return '0';
  }

  @override
  Future<bool> isConnected() {
    // TODO: implement isConnected
    return null;
  }

  @override
  Future rescan({int restoreHeight = 0}) {
    // TODO: implement rescan
    return null;
  }

  @override
  Future startSync() {
    // TODO: implement startSync
    return null;
  }

  @override
  Future updateInfo() async {
    _name.value = await getName();
    _address.value = await getAddress();
  }
}