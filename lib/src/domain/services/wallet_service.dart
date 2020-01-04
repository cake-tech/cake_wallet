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
  Observable<Wallet> get onWalletChange => _onWalletChanged.stream;
  Observable<Balance> get onBalanceChange => _onBalanceChange.stream;
  Observable<SyncStatus> get syncStatus => _syncStatus.stream;
  Observable<String> get onAddressChange => _currentWallet.onAddressChange;
  Observable<String> get onNameChange => _currentWallet.onNameChange;
  String get address => _currentWallet.address;
  String get name => _currentWallet.name;
  SyncStatus get syncStatusValue => _syncStatus.value;
  WalletType get walletType => _currentWallet.walletType;

  get currentWallet => _currentWallet;

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

  WalletService() {
    _currentWallet = null;
    walletType = WalletType.none;
    _syncStatus = BehaviorSubject<SyncStatus>();
    _onBalanceChange = BehaviorSubject<Balance>();
    _onWalletChanged = BehaviorSubject<Wallet>();
  }

  WalletDescription description;

  WalletType getType() => WalletType.monero;

  Future<String> getFilename() => _currentWallet.getFilename();

  Future<String> getName() => _currentWallet.getName();

  Future<String> getAddress() => _currentWallet.getAddress();

  Future<String> getSeed() => _currentWallet.getSeed();

  Future<Map<String, String>> getKeys() => _currentWallet.getKeys();

  Future<String> getFullBalance() => _currentWallet.getFullBalance();

  Future<String> getUnlockedBalance() => _currentWallet.getUnlockedBalance();

  Future<int> getCurrentHeight() => _currentWallet.getCurrentHeight();

  Future<int> getNodeHeight() => _currentWallet.getNodeHeight();

  Future<bool> isConnected() => _currentWallet.isConnected();

  Future close() => _currentWallet.close();

  Future connectToNode({Node node, bool useSSL = false, bool isLightWallet = false}) =>
      _currentWallet.connectToNode(
          node: node,
          useSSL: useSSL,
          isLightWallet: isLightWallet);

  Future startSync() => _currentWallet.startSync();

  TransactionHistory getHistory() => _currentWallet.getHistory();

  Future<PendingTransaction> createTransaction(
          TransactionCreationCredentials credentials) =>
      _currentWallet.createTransaction(credentials);

  Future updateInfo() async => _currentWallet.updateInfo();

  Future rescan({int restoreHeight = 0}) async => _currentWallet.rescan(restoreHeight: restoreHeight);
}
