import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cw_decred/api/libdcrwallet_bindings.dart';
import 'package:cw_decred/api/util.dart';

final String libraryName =
    Platform.isAndroid || Platform.isLinux // TODO: Linux.
        ? 'libdcrwallet.so'
        : 'cw_decred.framework/cw_decred';

final dcrwalletApi = libdcrwallet(DynamicLibrary.open(libraryName));

/// initLibdcrwallet initializes libdcrwallet using the provided logDir and gets
/// it ready for use. This must be done before attempting to create, load or use
/// a wallet.
void initLibdcrwallet(String logDir) {
  final cLogDIr = logDir.toCString();
  handleErrorAndPointers(
    fn: () => dcrwalletApi.initialize(cLogDIr),
    ptrsToFree: [cLogDIr],
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

  handleErrorAndPointers(
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

  handleErrorAndPointers(
    fn: () => dcrwalletApi.loadWallet(name, dataDir, network),
    ptrsToFree: [name, dataDir, network],
  );
}

void closeWallet(String walletName) {
  // TODO.
}

Future<void> changeWalletPassword(
    String walletName, String currentPassword, String newPassword) async {
  // TODO.
}

String? walletSeed(String walletName, String walletPassword) {
  final cName = walletName.toCString();
  final pass = walletPassword.toCString();
  final seed = dcrwalletApi.walletSeed(cName, pass);
  freePointers([cName, pass]);
  return seed.toDartString();
}

String? currentReceiveAddress(String walletName) {
  final cName = walletName.toCString();
  final currentAddress = dcrwalletApi.currentReceiveAddress(cName);
  cName.free();
  return currentAddress.toDartString();
}

Map balance(String walletName) {
  final cName = walletName.toCString();
  final balJson = dcrwalletApi.walletBalance(cName).toDartString();
  cName.free();
  return jsonDecode(balJson!);
}

int calculateEstimatedFeeWithFeeRate(int feeRate, int amount) {
  // Ideally we create a tx with wallet going to this amount and just return
  // the fee we get back. TODO.
  return 123000;
}
