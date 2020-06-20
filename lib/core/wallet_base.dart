import 'package:flutter/foundation.dart';
import 'package:cake_wallet/core/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';

abstract class WalletBase<BalaceType> {
  WalletType type;

  String get name;

  String address;

  BalaceType balance;

  TransactionHistoryBase transactionHistory;

  Future<void> connectToNode({@required Node node});

  Future<void> startSync();

  Future<void> createTransaction(Object credentials);

  Future<void> save();
}
