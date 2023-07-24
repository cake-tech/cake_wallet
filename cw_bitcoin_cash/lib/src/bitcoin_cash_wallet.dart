import 'package:bitbox/bitbox.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin_cash/src/bitcoin_cash_transaction_history.dart';
import 'package:cw_bitcoin_cash/src/bitcoin_cash_transaction_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

import 'bitcoin_cash_balance.dart';
import 'bitcoin_cash_client.dart';
import 'bitcoin_cash_pending_transaction.dart';
import 'bitcoin_cash_wallet_addresses.dart';

part 'bitcoin_cash_wallet.g.dart';

class BitcoinCashWallet = BitcoinCashWalletBase with _$BitcoinCashWallet;

abstract class BitcoinCashWalletBase extends WalletBase<BitcoinCashBalance,
    BitcoinCashTransactionHistory, BitcoinCashTransactionInfo> with Store {
  BitcoinCashWalletBase(
      {required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      required this.mnemonic,
      required Uint8List seedBytes,
      List<BitcoinCashWalletAddresses>? initialAddresses,
      BitcoinCashClient? bitcoinCashClient,
      BitcoinCashBalance? initialBalance,
      CryptoCurrency? currency})
      : hd = bitcoin.HDWallet.fromSeed(seedBytes).derivePath("m/44'/145'/0'"),
        syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _isTransactionUpdating = false,
        balance = ObservableMap<CryptoCurrency, BitcoinCashBalance>.of(
            {currency ?? CryptoCurrency.bch: initialBalance ?? BitcoinCashBalance(0)}),
        this.unspentCoinsInfo = unspentCoinsInfo,
        super(walletInfo) {
    this.bitcoinCashClient = bitcoinCashClient ?? BitcoinCashClient();
    this.walletInfo = walletInfo;
    walletAddresses = BitcoinCashWalletAddresses(walletInfo, mainHd: hd);
    transactionHistory = BitcoinCashTransactionHistory(walletInfo: walletInfo, password: password);
  }

  final bitcoin.HDWallet hd;
  final String mnemonic;

  late BitcoinCashClient bitcoinCashClient;
  Box<UnspentCoinsInfo> unspentCoinsInfo;

  @override
  String get seed => mnemonic;

  @override
  late BitcoinCashWalletAddresses walletAddresses;

  @override
  @observable
  late ObservableMap<CryptoCurrency, BitcoinCashBalance> balance;

  @override
  @observable
  SyncStatus syncStatus;

  String _password;
  bool _isTransactionUpdating;

  static Future<BitcoinCashWallet> create({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    List<BitcoinCashWalletAddresses>? initialAddresses,
    BitcoinCashBalance? initialBalance,
  }) async {
    return BitcoinCashWallet(
        mnemonic: mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        initialAddresses: initialAddresses,
        initialBalance: initialBalance,
        seedBytes: Mnemonic.toSeed(mnemonic));
  }

  @override
  Future<void> init() async {
    UnimplementedError();
  }
  @override
  Future<void> save() async {
    UnimplementedError();
  }
  @override
  Future<void> connectToNode({required Node node}) async {
    UnimplementedError();
  }
  @override
  Future<void> startSync() async {
    UnimplementedError();
  }
  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    return BitcoinCashPendingTransaction();
  }
  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    return 1;
  }

  @override
  Future<void> updateBalance() async {
    UnimplementedError();
  }

  @override
  Future<void> changePassword(String newPassword) async {
    UnimplementedError();
  }
  @override
  void close() {
    UnimplementedError();
  }

  @override
  Future<Map<String, BitcoinCashTransactionInfo>> fetchTransactions() async {
    return {};
  }

  @override
  Future<void> rescan({required int height}) async {
    UnimplementedError();
  }

  @override
  Future<void> renameWalletFiles(String newName) async {
    UnimplementedError();
  }

  @override
  Object get keys => throw UnimplementedError("keys");
}
