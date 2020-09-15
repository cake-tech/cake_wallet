import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/common/wallet_info.dart';
import 'package:cake_wallet/core/pending_transaction.dart';
import 'package:cake_wallet/core/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';

// FIXME: Move me.
CryptoCurrency currencyForWalletType(WalletType type) {
  switch (type) {
    case WalletType.bitcoin:
      return CryptoCurrency.btc;
    case WalletType.monero:
      return CryptoCurrency.xmr;
    default:
      return null;
  }
}

abstract class WalletBase<BalaceType> {
  WalletBase(this.walletInfo);

  static String idFor(String name, WalletType type) =>
      walletTypeToString(type).toLowerCase() + '_' + name;

  WalletInfo walletInfo;

  WalletType get type => walletInfo.type;

  CryptoCurrency get currency => currencyForWalletType(type);

  String get id => walletInfo.id;

  String get name => walletInfo.name;

  String get address;

  set address(String address);

  BalaceType get balance;

  SyncStatus get syncStatus;

  set syncStatus(SyncStatus status);

  String get seed;

  Object get keys;

  TransactionHistoryBase transactionHistory;

  Future<void> connectToNode({@required Node node});

  Future<void> startSync();

  Future<PendingTransaction> createTransaction(Object credentials);

  double calculateEstimatedFee(TransactionPriority priority);

  Future<void> save();
}
