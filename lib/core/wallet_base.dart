import 'package:flutter/foundation.dart';
import 'package:cake_wallet/core/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';

abstract class WalletBase<BalaceType> {
  WalletType type;

  CryptoCurrency currency;

  String get name;

  String address;

  BalaceType balance;

  SyncStatus syncStatus;

  String get seed;

  Object get keys;

  TransactionHistoryBase transactionHistory;

  String get id => walletTypeToString(type).toLowerCase() + '_' + name;

  Future<void> connectToNode({@required Node node});

  Future<void> startSync();

  Future<void> createTransaction(Object credentials);

  Future<void> save();
}
