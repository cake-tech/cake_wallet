import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/pending_transaction.dart';
import 'package:cake_wallet/src/domain/common/transaction_creation_credentials.dart';
import 'package:cake_wallet/src/domain/common/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/src/observables/observable.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/src/domain/common/wallet_info.dart';

class BitcoinWallet extends Wallet {
  BitcoinWallet({this.walletInfoSource, this.walletInfo});

  static const platform = MethodChannel('com.cakewallet.cake_wallet/bitcoin-wallet');

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

    /*if (walletInfo.isRecovery) {
      wallet.setRecoveringFromSeed();

      if (walletInfo.restoreHeight != null) {
        wallet.setRefreshFromBlockHeight(height: walletInfo.restoreHeight);
      }
    }*/

    return wallet;
  }

  Box<WalletInfo> walletInfoSource;
  WalletInfo walletInfo;

  @override
  // TODO: implement address
  String get address => null;

  @override
  Future close() {
    // TODO: implement close
    return null;
  }

  @override
  Future connectToNode({Node node, bool useSSL = false, bool isLightWallet = false}) {
    // TODO: implement connectToNode
    return null;
  }

  @override
  Future<PendingTransaction> createTransaction(TransactionCreationCredentials credentials) {
    // TODO: implement createTransaction
    return null;
  }

  @override
  Future<String> getAddress() {
    // TODO: implement getAddress
    return null;
  }

  @override
  Future<int> getCurrentHeight() {
    // TODO: implement getCurrentHeight
    return null;
  }

  @override
  Future<String> getFilename() {
    // TODO: implement getFilename
    return null;
  }

  @override
  Future<String> getFullBalance() {
    // TODO: implement getFullBalance
    return null;
  }

  @override
  TransactionHistory getHistory() {
    // TODO: implement getHistory
    return null;
  }

  @override
  Future<Map<String, String>> getKeys() {
    // TODO: implement getKeys
    return null;
  }

  @override
  Future<String> getName() {
    // TODO: implement getName
    return null;
  }

  @override
  Future<int> getNodeHeight() {
    // TODO: implement getNodeHeight
    return null;
  }

  @override
  Future<String> getSeed() {
    // TODO: implement getSeed
    return null;
  }

  @override
  WalletType getType() {
    // TODO: implement getType
    return null;
  }

  @override
  Future<String> getUnlockedBalance() {
    // TODO: implement getUnlockedBalance
    return null;
  }

  @override
  Future<bool> isConnected() {
    // TODO: implement isConnected
    return null;
  }

  @override
  // TODO: implement name
  String get name => null;

  @override
  // TODO: implement onAddressChange
  Observable<String> get onAddressChange => null;

  @override
  // TODO: implement onNameChange
  Observable<String> get onNameChange => null;

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
  Future updateInfo() {
    // TODO: implement updateInfo
    return null;
  }
}