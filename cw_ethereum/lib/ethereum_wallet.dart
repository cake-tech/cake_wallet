import 'dart:async';
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
import 'package:cw_ethereum/ethereum_client.dart';
import 'package:cw_ethereum/ethereum_transaction_history.dart';
import 'package:cw_ethereum/ethereum_transaction_info.dart';
import 'package:cw_ethereum/ethereum_wallet_addresses.dart';
import 'package:cw_ethereum/file.dart';
import 'package:mobx/mobx.dart';
import 'package:web3dart/web3dart.dart';

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
    EthereumBalance? initialBalance,
  })  : syncStatus = NotConnectedSyncStatus(),
        _password = password,
        walletAddresses = EthereumWalletAddresses(walletInfo),
        balance = ObservableMap<CryptoCurrency, EthereumBalance>.of(
            {CryptoCurrency.eth: initialBalance ?? EthereumBalance(0, 0)}),
        super(walletInfo) {
    this.walletInfo = walletInfo;
    transactionHistory = EthereumTransactionHistory();
    walletAddresses.address = EthPrivateKey.fromHex(privateKey).address.toString();
  }

  final String mnemonic;
  final String privateKey;
  final String _password;

  late EthereumClient _client;

  EtherAmount? _gasPrice;

  @override
  WalletAddresses walletAddresses;

  @override
  SyncStatus syncStatus;

  @override
  @observable
  late ObservableMap<CryptoCurrency, EthereumBalance> balance;

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    throw UnimplementedError("calculateEstimatedFee");
  }

  @override
  Future<void> changePassword(String password) {
    throw UnimplementedError("changePassword");
  }

  @override
  void close() {}

  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();

      final isConnected = await _client.connect(node);

      if (!isConnected) {
        throw Exception("Ethereum Node connection failed");
      }

      _updateBalance();

      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) {
    throw UnimplementedError("createTransaction");
  }

  @override
  Future<Map<String, EthereumTransactionInfo>> fetchTransactions() {
    throw UnimplementedError("fetchTransactions");
  }

  @override
  Object get keys => throw UnimplementedError("keys");

  @override
  Future<void> rescan({required int height}) {
    throw UnimplementedError("rescan");
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
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();
      await _updateBalance();
      _gasPrice = await _client.getGasPrice();

      Timer.periodic(
          const Duration(minutes: 1), (timer) async => _gasPrice = await _client.getGasPrice());

      syncStatus = SyncedSyncStatus();
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  int feeRate() {
    if (_gasPrice != null) {
      return _gasPrice!.getInEther.toInt();
    }

    return 0;
  }

  Future<String> makePath() async => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  String toJSON() => json.encode({
        'mnemonic': mnemonic,
        'balance': balance[currency]!.toJSON(),
        // TODO: save other attributes
      });

  Future<void> _updateBalance() async {
    balance[currency] = await _fetchBalances();
    await save();
  }

  Future<EthereumBalance> _fetchBalances() async {
    final balance = await _client.getBalance(privateKey);

    return EthereumBalance(balance.getInEther.toInt(), balance.getInEther.toInt());
  }
}
