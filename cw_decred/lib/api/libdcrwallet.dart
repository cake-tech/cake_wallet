import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cw_decred/api/libdcrwallet_bindings.dart';
import 'package:cw_decred/api/util.dart';

final int ErrCodeNotSynced = 1;

final String libraryName =
    Platform.isAndroid || Platform.isLinux // TODO: Linux.
        ? 'libdcrwallet.so'
        : 'cw_decred.framework/cw_decred';

final dcrwalletApi = libdcrwallet(DynamicLibrary.open(libraryName));

/// initLibdcrwallet initializes libdcrwallet using the provided logDir and gets
/// it ready for use. This must be done before attempting to create, load or use
/// a wallet.
void initLibdcrwallet(String logDir) {
  final cLogDir = logDir.toCString();
  executePayloadFn(
    fn: () => dcrwalletApi.initialize(cLogDir),
    ptrsToFree: [cLogDir],
  );
}

/// createWalletAsync calls the libdcrwallet's createWallet function
/// asynchronously.
Future<void> createWalletAsync(
    {required String name, required String dataDir, required String password}) {
  final args = <String, String>{
    "name": name,
    "dataDir": dataDir,
    "password": password,
  };
  return compute(createWalletSync, args);
}

/// createWalletSync calls the libdcrwallet's createWallet function
/// synchronously.
void createWalletSync(Map<String, String> args) {
  final name = args["name"]!.toCString();
  final dataDir = args["dataDir"]!.toCString();
  final password = args["password"]!.toCString();
  final network = "testnet".toCString();

  executePayloadFn(
    fn: () => dcrwalletApi.createWallet(name, dataDir, network, password),
    ptrsToFree: [name, dataDir, network, password],
  );
}

/// loadWalletAsync calls the libdcrwallet's loadWallet function asynchronously.
Future<void> loadWalletAsync({required String name, required String dataDir}) {
  final args = <String, String>{
    "name": name,
    "dataDir": dataDir,
  };
  return compute(loadWalletSync, args);
}

/// loadWalletSync calls the libdcrwallet's loadWallet function synchronously.
void loadWalletSync(Map<String, String> args) {
  final name = args["name"]!.toCString();
  final dataDir = args["dataDir"]!.toCString();
  final network = "testnet".toCString();
  executePayloadFn(
    fn: () => dcrwalletApi.loadWallet(name, dataDir, network),
    ptrsToFree: [name, dataDir, network],
  );
}

Future<void> startSyncAsync({required String name, required String peers}) {
  final args = <String, String>{
    "name": name,
    "peers": peers,
  };
  return compute(startSync, args);
}

void startSync(Map<String, String> args) {
  final name = args["name"]!.toCString();
  final peers = args["peers"]!.toCString();
  executePayloadFn(
    fn: () => dcrwalletApi.syncWallet(name, peers),
    ptrsToFree: [name, peers],
  );
}

void closeWallet(String walletName) {
  final name = walletName.toCString();
  executePayloadFn(
    fn: () => dcrwalletApi.closeWallet(name),
    ptrsToFree: [name],
  );
}

Future<void> changeWalletPassword(
    String walletName, String currentPassword, String newPassword) async {
  // TODO.
}

String? walletSeed(String walletName, String walletPassword) {
  final cName = walletName.toCString();
  final pass = walletPassword.toCString();
  final res = executePayloadFn(
    fn: () => dcrwalletApi.walletSeed(cName, pass),
    ptrsToFree: [cName, pass],
  );
  return res.payload;
}

String? currentReceiveAddress(String walletName) {
  final cName = walletName.toCString();
  final res = executePayloadFn(
    fn: () => dcrwalletApi.currentReceiveAddress(cName),
    ptrsToFree: [cName],
    skipErrorCheck: true, // errCode is checked below, before checking err
  );

  if (res.errCode == ErrCodeNotSynced) {
    // Wallet is not synced. We do not want to give out a used address so give
    // nothing.
    return null;
  }
  checkErr(res.err);
  return res.payload;
}

String syncStatus(String walletName) {
  final cName = walletName.toCString();
  final res = executePayloadFn(
    fn: () => dcrwalletApi.syncWalletStatus(cName),
    ptrsToFree: [cName],
  );
  return res.payload;
}

Map balance(String walletName) {
  final cName = walletName.toCString();
  final res = executePayloadFn(
    fn: () => dcrwalletApi.walletBalance(cName),
    ptrsToFree: [cName],
  );
  return jsonDecode(res.payload);
}

String estimateFee(String walletName, int numBlocks) {
  final cName = walletName.toCString();
  final cNumBlocks = numBlocks.toString().toCString();
  final res = executePayloadFn(
    fn: () => dcrwalletApi.estimateFee(cName, cNumBlocks),
    ptrsToFree: [cName, cNumBlocks],
  );
  return res.payload;
}

String createSignedTransaction(
    String walletName, String createSignedTransactionReq) {
  final cName = walletName.toCString();
  final cCreateSignedTransactionReq = createSignedTransactionReq.toCString();
  final res = executePayloadFn(
    fn: () => dcrwalletApi.createSignedTransaction(
        cName, cCreateSignedTransactionReq),
    ptrsToFree: [cName, cCreateSignedTransactionReq],
  );
  return res.payload;
}

String sendRawTransaction(String walletName, String txHex) {
  final cName = walletName.toCString();
  final cTxHex = txHex.toCString();
  final res = executePayloadFn(
    fn: () => dcrwalletApi.sendRawTransaction(cName, cTxHex),
    ptrsToFree: [cName, cTxHex],
  );
  return res.payload;
}

String listTransactions(String walletName, String from, String count) {
  final cName = walletName.toCString();
  final cFrom = from.toCString();
  final cCount = count.toCString();
  final res = executePayloadFn(
    fn: () => dcrwalletApi.listTransactions(cName, cFrom, cCount),
    ptrsToFree: [cName, cFrom, cCount],
  );
  return res.payload;
}

String bestBlock(String walletName) {
  final cName = walletName.toCString();
  final res = executePayloadFn(
    fn: () => dcrwalletApi.bestBlock(cName),
    ptrsToFree: [cName],
  );
  return res.payload;
}

String listUnspents(String walletName) {
  final cName = walletName.toCString();
  final res = executePayloadFn(
    fn: () => dcrwalletApi.listUnspents(cName),
    ptrsToFree: [cName],
  );
  return res.payload;
}

String rescanFromHeight(String walletName, String height) {
  final cName = walletName.toCString();
  final cHeight = height.toCString();
  final res = executePayloadFn(
    fn: () => dcrwalletApi.rescanFromHeight(cName, cHeight),
    ptrsToFree: [cName, cHeight],
  );
  return res.payload;
}

Future<String> signMessageAsync(
    String name, String message, String address, String walletPass) {
  final args = <String, String>{
    "walletname": name,
    "message": message,
    "address": address,
    "walletpass": walletPass,
  };
  return compute(signMessage, args);
}

String signMessage(Map<String, String> args) {
  final cName = args["walletname"]!.toCString();
  final cMessage = args["message"]!.toCString();
  final cAddress = args["address"]!.toCString();
  final cPass = args["walletpass"]!.toCString();
  final res = executePayloadFn(
    fn: () => dcrwalletApi.signMessage(cName, cMessage, cAddress, cPass),
    ptrsToFree: [cName, cMessage, cAddress, cPass],
  );
  return res.payload;
}
