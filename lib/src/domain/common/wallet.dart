import 'package:rxdart/rxdart.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/common/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/common/transaction_creation_credentials.dart';
import 'package:cake_wallet/src/domain/common/pending_transaction.dart';
import 'package:cake_wallet/src/domain/common/balance.dart';
import 'package:cake_wallet/src/domain/common/node.dart';

abstract class Wallet {
  WalletType getType();

  WalletType walletType;

  Observable<Balance> onBalanceChange;

  Observable<SyncStatus> syncStatus;

  Observable<String> get onNameChange;

  Observable<String> get onAddressChange;

  String get name;

  String get address;

  Future updateInfo();

  Future<String> getFilename();

  Future<String> getName();

  Future<String> getAddress();

  Future<String> getSeed();

  Future<Map<String, String>> getKeys();

  Future<String> getFullBalance();

  Future<String> getUnlockedBalance();

  Future<int> getCurrentHeight();

  Future<int> getNodeHeight();

  Future<bool> isConnected();

  Future close();

  TransactionHistory getHistory();

  Future connectToNode({Node node, bool useSSL = false, bool isLightWallet = false});

  Future startSync();

  Future<PendingTransaction> createTransaction(
      TransactionCreationCredentials credentials);

  Future rescan({int restoreHeight = 0});
}
