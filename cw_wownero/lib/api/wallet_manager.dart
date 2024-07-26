import 'dart:ffi';
import 'dart:isolate';

import 'package:cw_wownero/api/account_list.dart';
import 'package:cw_wownero/api/exceptions/wallet_creation_exception.dart';
import 'package:cw_wownero/api/exceptions/wallet_opening_exception.dart';
import 'package:cw_wownero/api/exceptions/wallet_restore_from_keys_exception.dart';
import 'package:cw_wownero/api/exceptions/wallet_restore_from_seed_exception.dart';
import 'package:cw_wownero/api/transaction_history.dart';
import 'package:cw_wownero/api/wallet.dart';
import 'package:monero/wownero.dart' as wownero;

wownero.WalletManager? _wmPtr;
final wownero.WalletManager wmPtr = Pointer.fromAddress((() {
  try {
    // Problems with the wallet? Crashes? Lags? this will print all calls to wow
    // codebase, so it will be easier to debug what happens. At least easier
    // than plugging gdb in. Especially on windows/android.
    wownero.printStarts = false;
    _wmPtr ??= wownero.WalletManagerFactory_getWalletManager();
    print("ptr: $_wmPtr");
  } catch (e) {
    print(e);
    rethrow;
  }
  return _wmPtr!.address;
})());

void createWalletSync(
    {required String path,
    required String password,
    required String language,
    int nettype = 0}) {
  txhistory = null;
  final newWptr = wownero.WalletManager_createWallet(wmPtr,
      path: path, password: password, language: language, networkType: 0);

  final status = wownero.Wallet_status(newWptr);
  if (status != 0) {
    throw WalletCreationException(message: wownero.Wallet_errorString(newWptr));
  }
  wptr = newWptr;
  wownero.Wallet_store(wptr!, path: path);
  openedWalletsByPath[path] = wptr!;

  // is the line below needed?
  // setupNodeSync(address: "node.wowneroworld.com:18089");
}

bool isWalletExistSync({required String path}) {
  return wownero.WalletManager_walletExists(wmPtr, path);
}

void restoreWalletFromSeedSync(
    {required String path,
    required String password,
    required String seed,
    int nettype = 0,
    int restoreHeight = 0}) {
  var newWptr;
  if (seed.split(" ").length == 14) {
    txhistory = null;
    newWptr = wownero.WOWNERO_deprecated_restore14WordSeed(
      path: path,
      password: password,
      language: seed, // I KNOW - this is supposed to be called seed
      networkType: 0,
    );

    setRefreshFromBlockHeight(
      height: wownero.WOWNERO_deprecated_14WordSeedHeight(seed: seed),
    );
  } else {
    txhistory = null;
    newWptr = wownero.WalletManager_recoveryWallet(
      wmPtr,
      path: path,
      password: password,
      mnemonic: seed,
      restoreHeight: restoreHeight,
      seedOffset: '',
      networkType: 0,
    );
  }

  final status = wownero.Wallet_status(newWptr);

  if (status != 0) {
    final error = wownero.Wallet_errorString(newWptr);
    throw WalletRestoreFromSeedException(message: error);
  }

  wptr = newWptr;

  openedWalletsByPath[path] = wptr!;
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
  final newWptr = wownero.WalletManager_createWalletFromKeys(
    wmPtr,
    path: path,
    password: password,
    restoreHeight: restoreHeight,
    addressString: address,
    viewKeyString: viewKey,
    spendKeyString: spendKey,
    nettype: 0,
  );

  final status = wownero.Wallet_status(newWptr);
  if (status != 0) {
    throw WalletRestoreFromKeysException(
        message: wownero.Wallet_errorString(newWptr));
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
  // wptr = wownero.WalletManager_createWalletFromKeys(
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
  final newWptr = wownero.WalletManager_createDeterministicWalletFromSpendKey(
    wmPtr,
    path: path,
    password: password,
    language: language,
    spendKeyString: spendKey,
    newWallet: true, // TODO(mrcyjanek): safe to remove
    restoreHeight: restoreHeight,
  );

  final status = wownero.Wallet_status(newWptr);

  if (status != 0) {
    final err = wownero.Wallet_errorString(newWptr);
    print("err: $err");
    throw WalletRestoreFromKeysException(message: err);
  }

  wptr = newWptr;

  wownero.Wallet_setCacheAttribute(wptr!, key: "cakewallet.seed", value: seed);

  storeSync();

  openedWalletsByPath[path] = wptr!;
}

String _lastOpenedWallet = "";

// void restoreWowneroWalletFromDevice(
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

Map<String, wownero.wallet> openedWalletsByPath = {};

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
        wownero.Wallet_store(Pointer.fromAddress(addr));
      });
    }
    txhistory = null;
    final newWptr = wownero.WalletManager_openWallet(wmPtr,
        path: path, password: password);
    _lastOpenedWallet = path;
    final status = wownero.Wallet_status(newWptr);
    if (status != 0) {
      final err = wownero.Wallet_errorString(newWptr);
      print(err);
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

  createWalletSync(path: path, password: password, language: language);
}

void _restoreFromSeed(Map<String, dynamic> args) {
  final path = args['path'] as String;
  final password = args['password'] as String;
  final seed = args['seed'] as String;
  final restoreHeight = args['restoreHeight'] as int;

  restoreWalletFromSeedSync(
      path: path, password: password, seed: seed, restoreHeight: restoreHeight);
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
        int nettype = 0}) async =>
    _createWallet({
      'path': path,
      'password': password,
      'language': language,
      'nettype': nettype
    });

Future<void> restoreFromSeed(
        {required String path,
        required String password,
        required String seed,
        int nettype = 0,
        int restoreHeight = 0}) async =>
    _restoreFromSeed({
      'path': path,
      'password': password,
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
