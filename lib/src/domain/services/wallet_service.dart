import 'package:rxdart/rxdart.dart';
import 'package:cake_wallet/src/domain/common/balance.dart';
import 'package:cake_wallet/src/domain/common/wallet_description.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/common/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/common/transaction_creation_credentials.dart';
import 'package:cake_wallet/src/domain/common/pending_transaction.dart';
import 'package:cake_wallet/src/domain/common/node.dart';

class WalletService extends Wallet {
  WalletService() {
    _currentWallet = null;
    walletType = WalletType.none;
    _syncStatus = BehaviorSubject<SyncStatus>();
    _onBalanceChange = BehaviorSubject<Balance>();
    _onWalletChanged = BehaviorSubject<Wallet>();
  }

  @override
  Observable<Balance> get onBalanceChange => _onBalanceChange.stream;

  @override
  Observable<SyncStatus> get syncStatus => _syncStatus.stream;

  @override
  Observable<String> get onAddressChange => _currentWallet.onAddressChange;

  @override
  Observable<String> get onNameChange => _currentWallet.onNameChange;

  @override
  String get address => _currentWallet.address;

  @override
  String get name => _currentWallet.name;

  @override
  WalletType get walletType => _currentWallet.walletType;

  Observable<Wallet> get onWalletChange => _onWalletChanged.stream;

  SyncStatus get syncStatusValue => _syncStatus.value;

  Wallet get currentWallet => _currentWallet;

  set currentWallet(Wallet wallet) {
    _currentWallet = wallet;

    if (wallet == null) {
      return;
    }

    _currentWallet.onBalanceChange
        .listen((wallet) => _onBalanceChange.add(wallet));
    _currentWallet.syncStatus.listen((status) => _syncStatus.add(status));
    _onWalletChanged.add(wallet);

    final type = wallet.getType();
    wallet.getName().then(
        (name) => description = WalletDescription(name: name, type: type));
  }

  BehaviorSubject<Wallet> _onWalletChanged;
  BehaviorSubject<Balance> _onBalanceChange;
  BehaviorSubject<SyncStatus> _syncStatus;
  Wallet _currentWallet;

  WalletDescription description;

  @override
  WalletType getType() => _currentWallet.getType();

  @override
  Future<String> getFilename() => _currentWallet.getFilename();

  @override
  Future<String> getName() => _currentWallet.getName();

  @override
  Future<String> getAddress() => _currentWallet.getAddress();

  @override
  Future<String> getSeed() => _currentWallet.getSeed();

  @override
  Future<Map<String, String>> getKeys() => _currentWallet.getKeys();

  @override
  Future<String> getFullBalance() => _currentWallet.getFullBalance();

  @override
  Future<String> getUnlockedBalance() => _currentWallet.getUnlockedBalance();

  @override
  Future<int> getCurrentHeight() => _currentWallet.getCurrentHeight();

  @override
  Future<int> getNodeHeight() => _currentWallet.getNodeHeight();

  @override
  Future<bool> isConnected() => _currentWallet.isConnected();

  @override
  Future close() => _currentWallet.close();

  @override
  Future connectToNode(
          {Node node, bool useSSL = false, bool isLightWallet = false}) =>
      _currentWallet.connectToNode(
          node: node, useSSL: useSSL, isLightWallet: isLightWallet);

  @override
  Future startSync() => _currentWallet.startSync();

  @override
  TransactionHistory getHistory() => _currentWallet.getHistory();

  @override
  Future<PendingTransaction> createTransaction(
          TransactionCreationCredentials credentials) =>
      _currentWallet.createTransaction(credentials);

  @override
  Future updateInfo() async => _currentWallet.updateInfo();

  @override
  Future rescan({int restoreHeight = 0}) async =>
      _currentWallet.rescan(restoreHeight: restoreHeight);
}
