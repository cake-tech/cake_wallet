import 'dart:convert';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_nano/nano_balance.dart';
import 'package:cw_nano/nano_transaction_history.dart';
import 'package:cw_nano/nano_transaction_info.dart';
import 'package:mobx/mobx.dart';
import 'package:web3dart/credentials.dart';
import 'dart:async';
import 'dart:io';
import 'package:cw_nano/nano_wallet_addresses.dart';
import 'package:cw_nano/nano_wallet_keys.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:web3dart/web3dart.dart';

part 'nano_wallet.g.dart';

class NanoWallet = NanoWalletBase with _$NanoWallet;

abstract class NanoWalletBase
    extends WalletBase<NanoBalance, NanoTransactionHistory, NanoTransactionInfo> with Store {
  NanoWalletBase({
    required WalletInfo walletInfo,
    required String mnemonic,
    required String password,
    NanoBalance? initialBalance,
  })  : syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _mnemonic = mnemonic,
        _isTransactionUpdating = false,
        _priorityFees = [],
        walletAddresses = NanoWalletAddresses(walletInfo),
        balance = ObservableMap<CryptoCurrency, NanoBalance>.of({
          CryptoCurrency.nano: initialBalance ??
              NanoBalance(currentBalance: BigInt.zero, receivableBalance: BigInt.zero)
        }),
        super(walletInfo) {
    print("@@@@@ initializing nano wallet @@@@@");
    this.walletInfo = walletInfo;
    transactionHistory = NanoTransactionHistory();
  }

  final String _mnemonic;
  final String _password;

  List<int> _priorityFees;
  int? _gasPrice;
  bool _isTransactionUpdating;

  @override
  WalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  late ObservableMap<CryptoCurrency, NanoBalance> balance;

  Future<void> init() async {}

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    return 0;
  }

  @override
  Future<void> changePassword(String password) {
    print("e");
    throw UnimplementedError("changePassword");
  }

  @override
  void close() {
    // _client.stop();
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    print("f");
    throw UnimplementedError();
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    print("g");
    throw UnimplementedError();
  }

  Future<void> updateTransactions() async {
    print("h");
    throw UnimplementedError();
  }

  @override
  Future<Map<String, NanoTransactionInfo>> fetchTransactions() async {
    print("i");
    throw UnimplementedError();
  }

  @override
  Object get keys {
    print("j");
    throw UnimplementedError("keys");
  }

  @override
  Future<void> rescan({required int height}) {
    print("k");
    throw UnimplementedError("rescan");
  }

  @override
  Future<void> save() async {
    print("l");
    throw UnimplementedError();
  }

  @override
  String get seed => _mnemonic;

  @action
  @override
  Future<void> startSync() async {
    throw UnimplementedError();
  }

  int feeRate(TransactionPriority priority) {
    throw UnimplementedError();
  }

  static Future<NanoWallet> open({
    required String name,
    required String password,
    required WalletInfo walletInfo,
  }) async {
    throw UnimplementedError();
  }

  Future<void> _updateBalance() async {
    await save();
  }

  Future<void> _fetchErc20Balances() async {
    throw UnimplementedError();
  }

  Future<EthPrivateKey> getPrivateKey(String mnemonic, String password) async {
    print("o");
    throw UnimplementedError();
  }

  Future<void>? updateBalance() async => await _updateBalance();

  Future<void> addErc20Token(Erc20Token token) async {
    throw UnimplementedError();
  }

  Future<void> deleteErc20Token(Erc20Token token) async {
    throw UnimplementedError();
  }

  void _onNewTransaction(FilterEvent event) {
    throw UnimplementedError();
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    print("rename");
    throw UnimplementedError();
  }
}
