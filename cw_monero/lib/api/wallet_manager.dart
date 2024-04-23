
import 'dart:ffi';

import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/api/exceptions/wallet_creation_exception.dart';
import 'package:cw_monero/api/exceptions/wallet_opening_exception.dart';
import 'package:cw_monero/api/exceptions/wallet_restore_from_keys_exception.dart';
import 'package:cw_monero/api/exceptions/wallet_restore_from_seed_exception.dart';
import 'package:cw_monero/api/wallet.dart';
import 'package:monero/monero.dart' as monero;

monero.WalletManager? _wmPtr;
final monero.WalletManager wmPtr = Pointer.fromAddress((() {
  try {
    monero.printStarts = true;
    _wmPtr ??= monero.WalletManagerFactory_getWalletManager();
    print("ptr: $_wmPtr");
  } catch (e) {
    print(e);
  }
  return _wmPtr!.address;
})());

void createWalletSync(
    {required String path,
     required String password,
     required String language,
     int nettype = 0}) {
  wptr = monero.WalletManager_createWallet(wmPtr, path: path, password: password, language: language, networkType: 0);

  final status = monero.Wallet_status(wptr!);
  if (status != 0) {
    throw WalletCreationException(message: monero.Wallet_errorString(wptr!));
  }
  monero.Wallet_store(wptr!, path: path);

  // is the line below needed?
  // setupNodeSync(address: "node.moneroworld.com:18089");
}

bool isWalletExistSync({required String path}) {
  return monero.WalletManager_walletExists(wmPtr, path);
}

void restoreWalletFromSeedSync(
    {required String path,
    required String password,
    required String seed,
    int nettype = 0,
    int restoreHeight = 0}) {

  wptr = monero.WalletManager_recoveryWallet(
    wmPtr,
    path: path,
    password: password,
    mnemonic: seed,
    restoreHeight: restoreHeight,
    seedOffset: '',
    networkType: 0,
  );
  
  final status = monero.Wallet_status(wptr!);

  if (status != 0) {
    final error = monero.Wallet_errorString(wptr!);
    throw WalletRestoreFromSeedException(message: error);
  }
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

  wptr = monero.WalletManager_createWalletFromKeys(
    wmPtr,
    path: path,
    password: password,
    restoreHeight: restoreHeight,
    addressString: address,
    viewKeyString: viewKey,
    spendKeyString: spendKey,
    nettype: 0,
  );
  
  final status = monero.Wallet_status(wptr!);
  if (status != 0) {
    throw WalletRestoreFromKeysException(message: monero.Wallet_errorString(wptr!));
  }
}

void restoreWalletFromSpendKeySync(
    {required String path,
      required String password,
      required String seed,
      required String language,
      required String spendKey,
      int nettype = 0,
      int restoreHeight = 0}) {

  // wptr = monero.WalletManager_createWalletFromKeys(
  //   wmPtr,
  //   path: path,
  //   password: password,
  //   restoreHeight: restoreHeight,
  //   addressString: '',
  //   spendKeyString: spendKey,
  //   viewKeyString: '',
  //   nettype: 0,
  // );

  wptr = monero.WalletManager_createDeterministicWalletFromSpendKey(
    wmPtr,
    path: path,
    password: password,
    language: language,
    spendKeyString: spendKey,
    newWallet: true, // TODO(mrcyjanek): safe to remove
    restoreHeight: restoreHeight,
  );

  final status = monero.Wallet_status(wptr!);

  if (status != 0) {
    final err = monero.Wallet_errorString(wptr!);
    print("err: $err");
    throw WalletRestoreFromKeysException(message: err);
  }

  monero.Wallet_setCacheAttribute(wptr!, key: "cakewallet.seed", value: seed);

  storeSync();
}

String _lastOpenedWallet = "";

void loadWallet({
  required String path,
  required String password,
  int nettype = 0}) {
  try {
    if (wptr == null || path != _lastOpenedWallet) {
      if (wptr != null) {
        monero.Wallet_store(wptr!);
      }
      wptr = monero.WalletManager_openWallet(wmPtr, path: path, password: password);
      _lastOpenedWallet = path;
    }
  } catch (e) {
    print(e);
  }
  final status = monero.Wallet_status(wptr!);
  if (status != 0) {
    final err = monero.Wallet_errorString(wptr!);
    print(err);
    throw WalletOpeningException(message: err);
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

Future<void> _openWallet(Map<String, String> args) async =>
    loadWallet(path: args['path'] as String, password: args['password'] as String);

Future<bool> _isWalletExist(String path) async => isWalletExistSync(path: path);

void openWallet({required String path, required String password, int nettype = 0}) async =>
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
