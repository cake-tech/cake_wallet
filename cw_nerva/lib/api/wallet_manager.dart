import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_nerva/api/account_list.dart';
import 'package:cw_nerva/api/exceptions/wallet_creation_exception.dart';
import 'package:cw_nerva/api/exceptions/wallet_opening_exception.dart';
import 'package:cw_nerva/api/exceptions/wallet_restore_from_keys_exception.dart';
import 'package:cw_nerva/api/exceptions/wallet_restore_from_seed_exception.dart';
import 'package:cw_nerva/api/transaction_history.dart';
import 'package:cw_nerva/api/wallet.dart';
import 'package:flutter/foundation.dart';
import 'package:monero/nerva.dart' as nerva;

class MoneroCException implements Exception {
  final String message;

  MoneroCException(this.message);

  @override
  String toString() {
    return message;
  }
}

void checkIfMoneroCIsFine() {
  final cppCsCpp = nerva.NERVA_checksum_wallet2_api_c_cpp();
  final cppCsH = nerva.NERVA_checksum_wallet2_api_c_h();
  final cppCsExp = nerva.NERVA_checksum_wallet2_api_c_exp();

  final dartCsCpp = nerva.wallet2_api_c_cpp_sha256;
  final dartCsH = nerva.wallet2_api_c_h_sha256;
  final dartCsExp = nerva.wallet2_api_c_exp_sha256;

  if (cppCsCpp != dartCsCpp) {
    throw MoneroCException("monero_c and monero.dart cpp wrapper code mismatch.\nLogic errors can occur.\nRefusing to run in release mode.\ncpp: '$cppCsCpp'\ndart: '$dartCsCpp'");
  }

  if (cppCsH != dartCsH) {
    throw MoneroCException("monero_c and monero.dart cpp wrapper header mismatch.\nLogic errors can occur.\nRefusing to run in release mode.\ncpp: '$cppCsH'\ndart: '$dartCsH'");
  }

  if (cppCsExp != dartCsExp && (Platform.isIOS || Platform.isMacOS)) {
    throw MoneroCException("monero_c and monero.dart wrapper export list mismatch.\nLogic errors can occur.\nRefusing to run in release mode.\ncpp: '$cppCsExp'\ndart: '$dartCsExp'");
  }
}

nerva.WalletManager? _wmPtr;
final nerva.WalletManager wmPtr = Pointer.fromAddress((() {
  try {
    // Problems with the wallet? Crashes? Lags? this will print all calls to wow
    // codebase, so it will be easier to debug what happens. At least easier
    // than plugging gdb in. Especially on windows/android.
    nerva.printStarts = false;
    _wmPtr ??= nerva.WalletManagerFactory_getWalletManager();
    printV("ptr: $_wmPtr");
  } catch (e) {
    printV(e);
    rethrow;
  }
  return _wmPtr!.address;
})());

void createWalletSync(
    {required String path,
    required String password,
    required String language,
    required String passphrase,
    int nettype = 0}) {
  txhistory = null;
  final newWptr = nerva.WalletManager_createWallet(wmPtr,
      path: path, password: password, language: language, networkType: 0);

  final status = nerva.Wallet_status(newWptr);
  if (status != 0) {
    throw WalletCreationException(message: nerva.Wallet_errorString(newWptr));
  }
  wptr = newWptr;
  nerva.Wallet_setCacheAttribute(wptr!, key: "cakewallet.passphrase", value: passphrase);

  nerva.Wallet_store(wptr!, path: path);
  openedWalletsByPath[path] = wptr!;

  // is the line below needed?
  // setupNodeSync(address: "node.nervaworld.com:18089");
}

bool isWalletExistSync({required String path}) {
  return nerva.WalletManager_walletExists(wmPtr, path);
}

void restoreWalletFromSeedSync(
    {required String path,
    required String password,
    required String passphrase,
    required String seed,
    int nettype = 0,
    int restoreHeight = 0}) {
  txhistory = null;
  final newWptr = nerva.WalletManager_recoveryWallet(
    wmPtr,
    path: path,
    password: password,
    mnemonic: seed,
    restoreHeight: restoreHeight,
    seedOffset: passphrase,
    networkType: 0,
  );

  final status = nerva.Wallet_status(newWptr);

  if (status != 0) {
    final error = nerva.Wallet_errorString(newWptr);
    throw WalletRestoreFromSeedException(message: error);
  }

  wptr = newWptr;
  
  nerva.Wallet_setCacheAttribute(wptr!, key: "cakewallet.passphrase", value: passphrase);
  nerva.Wallet_setCacheAttribute(wptr!, key: "cakewallet.seed", value: seed);
  
  openedWalletsByPath[path] = wptr!;

  store();
}

void restoreWalletFromKeysSync(
    {required String path,
    required String password,
    required String language,
    required String address,
    required String viewKey,
    required String spendKey,
    int nettype = 0,
    int restoreHeight = 0}) {
  txhistory = null;
  var newWptr = (spendKey != "")
   ? nerva.WalletManager_createDeterministicWalletFromSpendKey(
    wmPtr,
    path: path,
    password: password,
    language: language,
    spendKeyString: spendKey, 
    newWallet: true, // TODO(mrcyjanek): safe to remove
    restoreHeight: restoreHeight)
   : nerva.WalletManager_createWalletFromKeys(
    wmPtr,
    path: path,
    password: password,
    restoreHeight: restoreHeight,
    addressString: address,
    viewKeyString: viewKey,
    spendKeyString: spendKey,
    nettype: 0,
  );

  final status = nerva.Wallet_status(newWptr);
  if (status != 0) {
    throw WalletRestoreFromKeysException(
        message: nerva.Wallet_errorString(newWptr));
  }
  // CW-712 - Try to restore deterministic wallet first, if the view key doesn't
  // match the view key provided
  if (spendKey != "") {
    final viewKeyRestored = nerva.Wallet_secretViewKey(newWptr);
    if (viewKey != viewKeyRestored && viewKey != "") {
      nerva.WalletManager_closeWallet(wmPtr, newWptr, false);
      File(path).deleteSync();
      File(path+".keys").deleteSync();
      newWptr = nerva.WalletManager_createWalletFromKeys(
        wmPtr,
        path: path,
        password: password,
        restoreHeight: restoreHeight,
        addressString: address,
        viewKeyString: viewKey,
        spendKeyString: spendKey,
        nettype: 0,
      );
      final status = nerva.Wallet_status(newWptr);
      if (status != 0) {
        throw WalletRestoreFromKeysException(
            message: nerva.Wallet_errorString(newWptr));
      }
    }
  }
  wptr = newWptr;

  openedWalletsByPath[path] = wptr!;
}



void restoreWalletFromSpendKeySync(
    {required String path,
    required String password,
    required String seed,
    required String language,
    required String spendKey,
    int nettype = 0,
    int restoreHeight = 0}) {
  // txhistory = null;
  // wptr = nerva.WalletManager_createWalletFromKeys(
  //   wmPtr,
  //   path: path,
  //   password: password,
  //   restoreHeight: restoreHeight,
  //   addressString: '',
  //   spendKeyString: spendKey,
  //   viewKeyString: '',
  //   nettype: 0,
  // );

  txhistory = null;
  final newWptr = nerva.WalletManager_createDeterministicWalletFromSpendKey(
    wmPtr,
    path: path,
    password: password,
    language: language,
    spendKeyString: spendKey,
    newWallet: true, // TODO(mrcyjanek): safe to remove
    restoreHeight: restoreHeight,
  );

  final status = nerva.Wallet_status(newWptr);

  if (status != 0) {
    final err = nerva.Wallet_errorString(newWptr);
    printV("err: $err");
    throw WalletRestoreFromKeysException(message: err);
  }

  wptr = newWptr;

  nerva.Wallet_setCacheAttribute(wptr!, key: "cakewallet.seed", value: seed);

  storeSync();

  openedWalletsByPath[path] = wptr!;
}

String _lastOpenedWallet = "";

// void restoreNervaWalletFromDevice(
//     {required String path,
//       required String password,
//       required String deviceName,
//       int nettype = 0,
//       int restoreHeight = 0}) {
//
//   final pathPointer = path.toNativeUtf8();
//   final passwordPointer = password.toNativeUtf8();
//   final deviceNamePointer = deviceName.toNativeUtf8();
//   final errorMessagePointer = ''.toNativeUtf8();
//
//   final isWalletRestored = restoreWalletFromDeviceNative(
//       pathPointer,
//       passwordPointer,
//       deviceNamePointer,
//       nettype,
//       restoreHeight,
//       errorMessagePointer) != 0;
//
//   calloc.free(pathPointer);
//   calloc.free(passwordPointer);
//
//   storeSync();
//
//   if (!isWalletRestored) {
//     throw WalletRestoreFromKeysException(
//         message: convertUTF8ToString(pointer: errorMessagePointer));
//   }
// }

Map<String, nerva.wallet> openedWalletsByPath = {};

void loadWallet(
    {required String path, required String password, int nettype = 0}) {
  if (openedWalletsByPath[path] != null) {
    txhistory = null;
    wptr = openedWalletsByPath[path]!;
    return;
  }
  if (wptr == null || path != _lastOpenedWallet) {
    if (wptr != null) {
      final addr = wptr!.address;
      Isolate.run(() {
        nerva.Wallet_store(Pointer.fromAddress(addr));
      });
    }
    txhistory = null;
    final newWptr = nerva.WalletManager_openWallet(wmPtr,
        path: path, password: password);

    _lastOpenedWallet = path;
    final status = nerva.Wallet_status(newWptr);
    if (status != 0) {
      final err = nerva.Wallet_errorString(newWptr);
      printV(err);
      throw WalletOpeningException(message: err);
    }
    wptr = newWptr;
    openedWalletsByPath[path] = wptr!;
  }
}

void _createWallet(Map<String, dynamic> args) {
  final path = args['path'] as String;
  final password = args['password'] as String;
  final language = args['language'] as String;
  final passphrase = args['passphrase'] as String;

  createWalletSync(path: path, password: password, language: language, passphrase: passphrase);
}

void _restoreFromSeed(Map<String, dynamic> args) {
  final path = args['path'] as String;
  final password = args['password'] as String;
  final passphrase = args['passphrase'] as String;
  final seed = args['seed'] as String;
  final restoreHeight = args['restoreHeight'] as int;

  restoreWalletFromSeedSync(
      path: path, password: password, passphrase: passphrase, seed: seed, restoreHeight: restoreHeight);
}

void _restoreFromKeys(Map<String, dynamic> args) {
  final path = args['path'] as String;
  final password = args['password'] as String;
  final language = args['language'] as String;
  final restoreHeight = args['restoreHeight'] as int;
  final address = args['address'] as String;
  final viewKey = args['viewKey'] as String;
  final spendKey = args['spendKey'] as String;

  restoreWalletFromKeysSync(
      path: path,
      password: password,
      language: language,
      restoreHeight: restoreHeight,
      address: address,
      viewKey: viewKey,
      spendKey: spendKey);
}

void _restoreFromSpendKey(Map<String, dynamic> args) {
  final path = args['path'] as String;
  final password = args['password'] as String;
  final seed = args['seed'] as String;
  final language = args['language'] as String;
  final spendKey = args['spendKey'] as String;
  final restoreHeight = args['restoreHeight'] as int;

  restoreWalletFromSpendKeySync(
      path: path,
      password: password,
      seed: seed,
      language: language,
      restoreHeight: restoreHeight,
      spendKey: spendKey);
}

Future<void> _openWallet(Map<String, String> args) async => loadWallet(
    path: args['path'] as String, password: args['password'] as String);

Future<bool> _isWalletExist(String path) async => isWalletExistSync(path: path);

void openWallet(
        {required String path,
        required String password,
        int nettype = 0}) async =>
    loadWallet(path: path, password: password, nettype: nettype);

Future<void> openWalletAsync(Map<String, String> args) async =>
    _openWallet(args);

Future<void> createWallet(
        {required String path,
        required String password,
        required String language,
        required String passphrase,
        int nettype = 0}) async =>
    _createWallet({
      'path': path,
      'password': password,
      'language': language,
      'passphrase': passphrase,
      'nettype': nettype
    });

Future<void> restoreFromSeed(
        {required String path,
        required String password,
        required String passphrase,
        required String seed,
        int nettype = 0,
        int restoreHeight = 0}) async =>
    _restoreFromSeed({
      'path': path,
      'password': password,
      'passphrase': passphrase,
      'seed': seed,
      'nettype': nettype,
      'restoreHeight': restoreHeight
    });

Future<void> restoreFromKeys(
        {required String path,
        required String password,
        required String language,
        required String address,
        required String viewKey,
        required String spendKey,
        int nettype = 0,
        int restoreHeight = 0}) async =>
    _restoreFromKeys({
      'path': path,
      'password': password,
      'language': language,
      'address': address,
      'viewKey': viewKey,
      'spendKey': spendKey,
      'nettype': nettype,
      'restoreHeight': restoreHeight
    });

Future<void> restoreFromSpendKey(
        {required String path,
        required String password,
        required String seed,
        required String language,
        required String spendKey,
        int nettype = 0,
        int restoreHeight = 0}) async =>
    _restoreFromSpendKey({
      'path': path,
      'password': password,
      'seed': seed,
      'language': language,
      'spendKey': spendKey,
      'nettype': nettype,
      'restoreHeight': restoreHeight
    });

Future<bool> isWalletExist({required String path}) => _isWalletExist(path);
