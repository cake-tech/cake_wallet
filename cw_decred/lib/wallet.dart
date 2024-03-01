import 'dart:io';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_decred/pending_transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

import 'package:cw_decred/api/libdcrwallet.dart' as libdcrwallet;
import 'package:cw_decred/transaction_history.dart';
import 'package:cw_decred/wallet_addresses.dart';
import 'package:cw_decred/transaction_priority.dart';
import 'package:cw_decred/balance.dart';
import 'package:cw_decred/transaction_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/unspent_transaction_output.dart';

part 'wallet.g.dart';

class DecredWallet = DecredWalletBase with _$DecredWallet;

abstract class DecredWalletBase extends WalletBase<DecredBalance,
    DecredTransactionHistory, DecredTransactionInfo> with Store {
  DecredWalletBase(WalletInfo walletInfo, String password)
      : _password = password,
        syncStatus = NotConnectedSyncStatus(),
        balance = ObservableMap.of({CryptoCurrency.dcr: DecredBalance.zero()}),
        super(walletInfo) {
    walletAddresses = DecredWalletAddresses(walletInfo);
    transactionHistory = DecredTransactionHistory();
  }

  // password is currently only used for seed display, but would likely also be
  // required to sign inputs when creating transactions.
  final String _password;

  // TODO: Set up a way to change the balance and sync status when dcrlibwallet
  // changes. Long polling probably?
  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  late ObservableMap<CryptoCurrency, DecredBalance> balance;

  @override
  late DecredWalletAddresses walletAddresses;

  @override
  String? get seed {
    return libdcrwallet.walletSeed(walletInfo.name, _password);
  }

  @override
  Object get keys {
    // throw UnimplementedError();
    return {};
  }

  Future<void> init() async {
    updateBalance();
    // TODO: update other wallet properties such as syncStatus, walletAddresses
    // and transactionHistory with data from libdcrwallet.
  }

  @override
  Future<void> connectToNode({required Node node}) async {
    //throw UnimplementedError();
  }

  @action
  @override
  Future<void> startSync() async {
    // TODO: call libdcrwallet.spvSync() and update syncStatus.
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    return DecredPendingTransaction(
        txid:
            "3cbf3eb9523fd04e96dbaf98cdbd21779222cc8855ece8700494662ae7578e02",
        amount: 12345678,
        fee: 1234,
        rawHex: "baadbeef");
  }

  int feeRate(TransactionPriority priority) {
    // TODO
    return 1000;
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    if (priority is DecredTransactionPriority) {
      return libdcrwallet.calculateEstimatedFeeWithFeeRate(
          this.feeRate(priority), amount ?? 0);
    }

    return 0;
  }

  @override
  Future<Map<String, DecredTransactionInfo>> fetchTransactions() async {
    // TODO: Read from libdcrwallet.
    final txInfo = DecredTransactionInfo(
      id: "3cbf3eb9523fd04e96dbaf98cdbd21779222cc8855ece8700494662ae7578e02",
      amount: 1234567,
      fee: 123,
      direction: TransactionDirection.outgoing,
      isPending: true,
      date: DateTime.now(),
      height: 0,
      confirmations: 0,
      to: "DsT4qJPPaYEuQRimfgvSKxKH3paysn1x3Nt",
    );
    return {
      "3cbf3eb9523fd04e96dbaf98cdbd21779222cc8855ece8700494662ae7578e02": txInfo
    };
  }

  @override
  Future<void> save() async {}

  @override
  Future<void> rescan({required int height}) async {
    // TODO.
  }

  @override
  void close() {
    libdcrwallet.closeWallet(walletInfo.name);
  }

  @override
  Future<void> changePassword(String password) async {
    await libdcrwallet.changeWalletPassword(
        walletInfo.name, _password, password);
  }

  @override
  Future<void>? updateBalance() async {
    final balanceMap = libdcrwallet.balance(walletInfo.name);
    balance[CryptoCurrency.dcr] = DecredBalance(
      confirmed: balanceMap["confirmed"] ?? 0,
      unconfirmed: balanceMap["unconfirmed"] ?? 0,
    );
  }

  @override
  void setExceptionHandler(void Function(FlutterErrorDetails) onError) =>
      onError;

  Future<void> renameWalletFiles(String newWalletName) async {
    final currentDirPath =
        await pathForWalletDir(name: walletInfo.name, type: type);

    final newDirPath = await pathForWalletDir(name: newWalletName, type: type);

    if (File(newDirPath).existsSync()) {
      throw "wallet already exists at $newDirPath";
    }
    ;

    await Directory(currentDirPath).rename(newDirPath);
  }

  @override
  String signMessage(String message, {String? address = null}) {
    return ""; // TODO
  }

  List<Unspent> unspents() {
    return [
      Unspent(
          "DsT4qJPPaYEuQRimfgvSKxKH3paysn1x3Nt",
          "3cbf3eb9523fd04e96dbaf98cdbd21779222cc8855ece8700494662ae7578e02",
          1234567,
          0,
          null)
    ];
  }
}
