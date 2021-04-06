import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/sync_status.dart';
import 'package:cake_wallet/entities/transaction_history.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/entities/transaction_creation_credentials.dart';
import 'package:cake_wallet/entities/pending_transaction.dart';
import 'package:cake_wallet/entities/balance.dart';
import 'package:cake_wallet/entities/node.dart';

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
