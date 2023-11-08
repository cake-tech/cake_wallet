import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:cw_decred/api/libdcrwallet_bindings.dart';

import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_decred/api/util.dart';
import 'package:cw_decred/balance.dart';
import 'package:cw_decred/pending_transaction.dart';
import 'package:cw_decred/transaction_info.dart';
import 'package:cw_core/transaction_direction.dart';

final String libraryName =
    Platform.isAndroid || Platform.isLinux // TODO: Linux.
        ? 'libdcrwallet.so'
        : 'cw_decred.framework/cw_decred';

final dcrwalletApi = libdcrwallet(DynamicLibrary.open(libraryName));

// Will it work if none of these are async functions?
class SPVWallet {
  // password is currently only used for seed display, can set to null after
  // seed backup is complete.
  final String password;
  final WalletInfo walletInfo;

  SPVWallet(this.password, this.walletInfo);

  /// Initializes libdcrwallet using the provided logDir and gets it ready for
  /// use. This must be done before attempting to create, load or use a wallet.
  static void init(String logDir) {
    final cLogDIr = logDir.toCString();
    handleErrorAndPointers(
      fn: () => dcrwalletApi.initialize(cLogDIr),
      ptrsToFree: [cLogDIr],
    );
  }

  static SPVWallet create(String password, String name, WalletInfo walletInfo) {
    final cName = name.toCString();
    final cDataDir = walletInfo.path.toCString();
    final cNet = "testnet".toCString();
    final cPass = password.toCString();

    handleErrorAndPointers(
      fn: () => dcrwalletApi.createWallet(cName, cDataDir, cNet, cPass),
      ptrsToFree: [cName, cDataDir, cNet, cPass],
    );

    return SPVWallet(password, walletInfo);
  }

  static SPVWallet load(String password, String name, WalletInfo walletInfo) {
    final cName = name.toCString();
    final cDataDir = walletInfo.path.toCString();
    final cNet = "testnet".toCString();

    handleErrorAndPointers(
      fn: () => dcrwalletApi.loadWallet(cName, cDataDir, cNet),
      ptrsToFree: [cName, cDataDir, cNet],
    );

    return SPVWallet(password, walletInfo);
  }

  String? seed() {
    final walletName = walletInfo.name.toCString();
    final pass = password.toCString();
    final seed = dcrwalletApi.walletSeed(walletName, pass);
    freePointers([walletName, pass]);
    return seed.toDartString();
  }

  DecredBalance balance() {
    final walletName = walletInfo.name.toCString();
    final balJson = dcrwalletApi.walletBalance(walletName).toDartString();
    walletName.free();

    final map = jsonDecode(balJson!);
    return DecredBalance(
      confirmed: map["confirmed"] ?? 0,
      unconfirmed: map["unconfirmed"] ?? 0,
    );
  }

  int feeRate(int priority) {
    return 1000;
  }

  int calculateEstimatedFeeWithFeeRate(int feeRate, int amount) {
    // Ideally we create a tx with wallet going to this amount and just return
    // the fee we get back.
    return 123000;
  }

  void close() {}

  DecredPendingTransaction createTransaction(Object credentials) {
    return DecredPendingTransaction(
        spv: this,
        txid:
            "3cbf3eb9523fd04e96dbaf98cdbd21779222cc8855ece8700494662ae7578e02",
        amount: 12345678,
        fee: 1234,
        rawHex: "baadbeef");
  }

  void rescan(int height) {
    sleep(Duration(seconds: 10));
  }

  void startSync() {
    sleep(Duration(seconds: 5));
  }

  SyncStatus syncStatus() {
    return SyncedSyncStatus();
  }

  int height() {
    return 400;
  }

  Map<String, DecredTransactionInfo> transactions() {
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

  String newAddress() {
    // external
    return "DsT4qJPPaYEuQRimfgvSKxKH3paysn1x3Nt";
  }

  List<String> addresses() {
    final walletName = walletInfo.name.toCString();
    final currentAddress =
        dcrwalletApi.currentReceiveAddress(walletName).toDartString();
    walletName.free();
    return currentAddress == null ? [] : [currentAddress];
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

  void changePassword(String newPW) {}

  void sendRawTransaction(String rawHex) {}

  String signMessage(String message, String? address) {
    return "abababababababab";
  }
}
