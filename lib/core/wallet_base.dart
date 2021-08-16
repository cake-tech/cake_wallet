import 'package:cake_wallet/entities/balance.dart';
import 'package:cake_wallet/entities/transaction_info.dart';
import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:cake_wallet/entities/wallet_addresses.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/core/pending_transaction.dart';
import 'package:cake_wallet/core/transaction_history.dart';
import 'package:cake_wallet/entities/currency_for_wallet_type.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/entities/sync_status.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/entities/wallet_type.dart';

abstract class WalletBase<
    BalanceType extends Balance,
    HistoryType extends TransactionHistoryBase,
    TransactionType extends TransactionInfo> {
  WalletBase(this.walletInfo);

  static String idFor(String name, WalletType type) =>
      walletTypeToString(type).toLowerCase() + '_' + name;

  WalletInfo walletInfo;

  WalletType get type => walletInfo.type;

  CryptoCurrency get currency => currencyForWalletType(type);

  String get id => walletInfo.id;

  String get name => walletInfo.name;

  //String get address;

  //set address(String address);

  BalanceType get balance;

  SyncStatus get syncStatus;

  set syncStatus(SyncStatus status);

  String get seed;

  Object get keys;

  WalletAddresses get walletAddresses;

  HistoryType transactionHistory;

  Future<void> connectToNode({@required Node node});

  Future<void> startSync();

  Future<PendingTransaction> createTransaction(Object credentials);

  int calculateEstimatedFee(TransactionPriority priority, int amount);

  // void fetchTransactionsAsync(
  //     void Function(TransactionType transaction) onTransactionLoaded,
  //     {void Function() onFinished});

  Future<Map<String, TransactionType>> fetchTransactions();

  Future<void> save();

  Future<void> rescan({int height});

  void close();
}
