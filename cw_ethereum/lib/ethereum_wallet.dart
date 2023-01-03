import 'dart:convert';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_ethereum/ethereum_balance.dart';
import 'package:cw_ethereum/ethereum_transaction_history.dart';
import 'package:cw_ethereum/ethereum_transaction_info.dart';
import 'package:cw_ethereum/ethereum_wallet_addresses.dart';
import 'package:cw_ethereum/file.dart';
import 'package:mobx/mobx.dart';

part 'ethereum_wallet.g.dart';

class EthereumWallet = EthereumWalletBase with _$EthereumWallet;

abstract class EthereumWalletBase
    extends WalletBase<EthereumBalance, EthereumTransactionHistory, EthereumTransactionInfo>
    with Store {
  EthereumWalletBase({
    required WalletInfo walletInfo,
    required this.mnemonic,
    required this.privateKey,
    required String password,
  })  : syncStatus = NotConnectedSyncStatus(),
        _password = password,
        walletAddresses = EthereumWalletAddresses(walletInfo),
        super(walletInfo) {
    this.walletInfo = walletInfo;
    transactionHistory = EthereumTransactionHistory();
  }

  final String mnemonic;
  final String privateKey;
  final String _password;

  @override
  SyncStatus syncStatus;

  @override
  ObservableMap<CryptoCurrency, EthereumBalance> get balance => throw UnimplementedError();

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword(String password) {
    throw UnimplementedError();
  }

  @override
  void close() {}

  @override
  Future<void> connectToNode({required Node node}) {
    throw UnimplementedError();
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, EthereumTransactionInfo>> fetchTransactions() {
    throw UnimplementedError();
  }

  @override
  Object get keys => throw UnimplementedError();

  @override
  Future<void> rescan({required int height}) {
    throw UnimplementedError();
  }

  @override
  Future<void> save() async {
    final path = await makePath();
    await write(path: path, password: _password, data: toJSON());
    await transactionHistory.save();
  }

  @override
  String get seed => mnemonic;

  @override
  Future<void> startSync() {
    throw UnimplementedError();
  }

  @override
  WalletAddresses walletAddresses;

  Future<String> makePath() async => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  String toJSON() => json.encode({
        'mnemonic': mnemonic,
        // TODO: save other attributes
      });
}
