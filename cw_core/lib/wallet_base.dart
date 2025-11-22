import 'package:mobx/mobx.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';

abstract class WalletBase<BalanceType extends Balance, HistoryType extends TransactionHistoryBase,
    TransactionType extends TransactionInfo> {
  WalletBase(this.walletInfo, this.derivationInfo);

  static String idFor(String name, WalletType type) =>
      walletTypeToString(type).toLowerCase() + '_' + name;

  WalletInfo walletInfo;
  DerivationInfo derivationInfo;

  WalletType get type => walletInfo.type;

  CryptoCurrency get currency => walletTypeToCryptoCurrency(type, isTestnet: isTestnet);

  String get id => walletInfo.id;

  String get name => walletInfo.name;

  //String get address;

  //set address(String address);

  ObservableMap<CryptoCurrency, BalanceType> get balance;

  String formatCryptoAmount(String amount) => amount;

  SyncStatus get syncStatus;

  set syncStatus(SyncStatus status);

  String? get seed;

  String? get privateKey => null;

  String? get hexSeed => null;

  String? get passphrase => null;

  Object get keys;

  WalletAddresses get walletAddresses;

  late HistoryType transactionHistory;

  set isEnabledAutoGenerateSubaddress(bool value) {}

  bool get isEnabledAutoGenerateSubaddress => false;

  bool get isHardwareWallet => walletInfo.isHardwareWallet;

  HardwareWalletType? get hardwareWalletType => walletInfo.hardwareWalletType;

  bool get hasRescan => false;

  Future<void> connectToNode({required Node node});

  // there is a default definition here because only coins with a pow node (nano based) need to override this
  Future<void> connectToPowNode({required Node node}) async {}

  // startBackgroundSync is used to start sync in the background, without doing any
  // extra things in the background.
  // startSync is used as a fallback.
  Future<void> startBackgroundSync() => startSync();
  Future<void> stopBackgroundSync(String password) => stopSync();

  Future<void> startSync();

  Future<void> stopSync() async {}

  Future<PendingTransaction> createTransaction(Object credentials);

  int calculateEstimatedFee(TransactionPriority priority, int? amount);

  Future<void> updateEstimatedFeesParams(TransactionPriority? priority) async {}

  // void fetchTransactionsAsync(
  //     void Function(TransactionType transaction) onTransactionLoaded,
  //     {void Function() onFinished});

  Future<Map<String, TransactionType>> fetchTransactions();

  Future<void> save();

  Future<void> rescan({required int height});

  Future<void> close({bool shouldCleanup = false});

  Future<void> changePassword(String password);

  String get password;

  Future<void>? updateBalance();
  Future<void> updateTransactionsHistory() async {}

  void setExceptionHandler(void Function(FlutterErrorDetails) onError) => null;

  Future<void> renameWalletFiles(String newWalletName);

  Future<String> signMessage(String message, {String? address = null});

  Future<bool> verifyMessage(String message, String signature, {String? address = null});

  bool isTestnet = false;

  bool canSend() => true;

  /// Check if the wallet's socket connection is healthy.
  /// Returns true if the connection is alive, false otherwise.
  /// Default implementation returns true (no-op for wallets without socket connections).
  Future<bool> checkSocketHealth() async => true;

  /// This is used to check if the current node is healthy by making a lightweight RPC call
  /// Each wallet implementation should override this to make a single, efficient call
  /// Returns true if the node is healthy, false otherwise
  Future<bool> checkNodeHealth();
}
