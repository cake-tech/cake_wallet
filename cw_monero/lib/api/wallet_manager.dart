import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/api/exceptions/wallet_creation_exception.dart';
import 'package:cw_monero/api/exceptions/wallet_opening_exception.dart';
import 'package:cw_monero/api/exceptions/wallet_restore_from_keys_exception.dart';
import 'package:cw_monero/api/exceptions/wallet_restore_from_seed_exception.dart';
import 'package:cw_monero/api/transaction_history.dart';
import 'package:cw_monero/api/wallet.dart';
import 'package:cw_monero/ledger.dart';
import 'package:flutter/foundation.dart';
import 'package:monero/src/monero.dart';
import 'package:monero/src/wallet2.dart';
import 'package:monero/monero.dart' as monero;
import 'package:cw_lws/src/wallet2.dart' as cw_lwswallet;
import 'package:cw_lws/src/monero.dart' as cw_lwssrc;
import 'package:cw_lws/monero.dart' as cw_lwsroot;

class MoneroCException implements Exception {
  final String message;

  MoneroCException(this.message);

  @override
  String toString() => message;
}

void checkIfMoneroCIsFine() {
  final checksum = MoneroWalletChecksum();
  final cppCsCpp = checksum.checksum_wallet2_api_c_cpp();
  final cppCsH = checksum.checksum_wallet2_api_c_h();
  final cppCsExp = checksum.checksum_wallet2_api_c_exp();

  final dartCsCpp = monero.wallet2_api_c_cpp_sha256;
  final dartCsH = monero.wallet2_api_c_h_sha256;
  final dartCsExp = monero.wallet2_api_c_exp_sha256;

  if (cppCsCpp != dartCsCpp) {
    throw MoneroCException(
        "monero_c and monero.dart cpp wrapper code mismatch.\nLogic errors can occur.\nRefusing to run in release mode.\ncpp: '$cppCsCpp'\ndart: '$dartCsCpp'");
  }

  if (cppCsH != dartCsH) {
    throw MoneroCException(
        "monero_c and monero.dart cpp wrapper header mismatch.\nLogic errors can occur.\nRefusing to run in release mode.\ncpp: '$cppCsH'\ndart: '$dartCsH'");
  }

  if (cppCsExp != dartCsExp && (Platform.isIOS || Platform.isMacOS)) {
    throw MoneroCException(
        "monero_c and monero.dart wrapper export list mismatch.\nLogic errors can occur.\nRefusing to run in release mode.\ncpp: '$cppCsExp'\ndart: '$dartCsExp'");
  }
}

Wallet2WalletManager? _wmPtr;
Wallet2WalletManager wmPtr = (() {
  try {
    // Problems with the wallet? Crashes? Lags? this will print all calls to xmr
    // codebase, so it will be easier to debug what happens. At least easier
    // than plugging gdb in. Especially on windows/android.
    monero.printStarts = false;
    // Identify here if the wallet is in LWS mode or not.

    // get global setting
    // if (Platform.isAndroid || Platform.isIOS) {
    //   final useLws = Platform.environment["MONERO_USE_LWS"] == "1";
    //   MoneroWalletManagerFactory().setUseLws(useLws);
    //   printV("Using LWS: $useLws");
    // }
    if (kDebugMode && debugMonero) {
      MoneroWalletManagerFactory().setLogLevel(4);
    }
    _wmPtr ??= MoneroWalletManagerFactory().getWalletManager();
    // KB: Why duplicate?
    printV("ptr: $_wmPtr"); //wmPtr: ptr: Instance of 'MoneroWalletManager'
  } catch (e) {
    printV(e);
    rethrow;
  }
  return _wmPtr!;
})();

// KB code
// TODO (KB): implement getCurrentWalletPtr
Future<dynamic> getCurrentWalletPtr() async {
  //return ;
}

Future<dynamic> getWmPtr() async {
  return _wmPtr;
}

// KB code ends

Wallet2Wallet createWalletPointer() {
  final newWptr = wmPtr.createWallet(path: "", password: "", language: "", networkType: 0);
  return newWptr;
}

void createWallet(
    {required String path,
    required String password,
    required String language,
    required String passphrase,
    int nettype = 0}) {
  txhistory = null;
  language = getSeedLanguage(language)!;
  final newW =
      wmPtr.createWallet(path: path, password: password, language: language, networkType: 0);

  int status = newW.status();
  if (status != 0) {
    throw WalletCreationException(message: newW.errorString());
  }
  newW.store(path: path);
  setupBackgroundSync(password, newW);
  newW.store(path: path);

  currentWallet = newW;
  currentWallet!.setCacheAttribute(key: "cakewallet.passphrase", value: passphrase);
  currentWallet!.store(path: path);
  openedWalletsByPath[path] = currentWallet!;
  _lastOpenedWallet = path;
}

bool isWalletExist({required String path}) {
  return wmPtr.walletExists(path);
}

void restoreWalletFromSeedSync(
    {required String path,
    required String password,
    required String passphrase,
    required String seed,
    int nettype = 0,
    int restoreHeight = 0}) {
  txhistory = null;
  final newW = wmPtr.recoveryWallet(
    path: path,
    password: password,
    mnemonic: seed,
    restoreHeight: restoreHeight,
    seedOffset: passphrase,
    networkType: 0,
  );

  final status = newW.status();

  if (status != 0) {
    final error = newW.errorString();
    if (error.contains('word list failed verification')) {
      throw WalletRestoreFromSeedException(
        message:
            "Seed verification failed, please make sure you entered the correct seed with the correct words order",
      );
    }
    throw WalletRestoreFromSeedException(message: error);
  }
  currentWallet = newW;

  setRefreshFromBlockHeight(height: restoreHeight);
  setupBackgroundSync(password, newW);

  currentWallet!.setCacheAttribute(key: "cakewallet.passphrase", value: passphrase);

  openedWalletsByPath[path] = currentWallet!;

  currentWallet!.store(path: path);
  _lastOpenedWallet = path;
}

void restoreWalletFromKeys(
    {required String path,
    required String password,
    required String language,
    required String address,
    required String viewKey,
    required String spendKey,
    int nettype = 0,
    int restoreHeight = 0}) {
  txhistory = null;
  var newW = (spendKey != "")
      ? wmPtr.createDeterministicWalletFromSpendKey(
          path: path,
          password: password,
          language: language,
          spendKeyString: spendKey,
          newWallet: true,
          // TODO(mrcyjanek): safe to remove
          restoreHeight: restoreHeight)
      : wmPtr.createWalletFromKeys(
          path: path,
          password: password,
          restoreHeight: restoreHeight,
          addressString: address,
          viewKeyString: viewKey,
          spendKeyString: spendKey,
          nettype: 0,
        );

  int status = newW.status();
  if (status != 0) {
    throw WalletRestoreFromKeysException(message: newW.errorString());
  }
  newW.store(path: path);

  // CW-712 - Try to restore deterministic wallet first, if the view key doesn't
  // match the view key provided
  if (spendKey != "") {
    final viewKeyRestored = newW.secretViewKey();
    if (viewKey != viewKeyRestored && viewKey != "") {
      wmPtr.closeWallet(newW, false);
      File(path).deleteSync();
      File(path + ".keys").deleteSync();
      newW = wmPtr.createWalletFromKeys(
        path: path,
        password: password,
        restoreHeight: restoreHeight,
        addressString: address,
        viewKeyString: viewKey,
        spendKeyString: spendKey,
        nettype: 0,
      );
      int status = newW.status();
      if (status != 0) {
        throw WalletRestoreFromKeysException(message: newW.errorString());
      }
      newW.store(path: path);

      setupBackgroundSync(password, newW);
    }
  }

  currentWallet = newW;

  openedWalletsByPath[path] = currentWallet!;
  _lastOpenedWallet = path;
}

// English only, because normalization.
void restoreWalletFromPolyseedWithOffset(
    {required String path,
    required String password,
    required String seed,
    required String seedOffset,
    required String language,
    int nettype = 0}) {
  txhistory = null;
  final newW = wmPtr.createWalletFromPolyseed(
    path: path,
    password: password,
    networkType: nettype,
    mnemonic: seed,
    seedOffset: seedOffset,
    newWallet: true, // safe to remove
    restoreHeight: 0,
    kdfRounds: 1,
  );

  int status = newW.status();

  if (status != 0) {
    final err = newW.errorString();
    printV("err: $err");
    throw WalletRestoreFromKeysException(message: err);
  }

  currentWallet = newW;

  currentWallet!.setCacheAttribute(key: "cakewallet.seed", value: seed);
  currentWallet!.setCacheAttribute(key: "cakewallet.passphrase", value: seedOffset);
  currentWallet!.store(path: path);

  setupBackgroundSync(password, currentWallet!);
  storeSync();

  openedWalletsByPath[path] = currentWallet!;
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

  txhistory = null;
  final newW = wmPtr.createDeterministicWalletFromSpendKey(
    path: path,
    password: password,
    language: language,
    spendKeyString: spendKey,
    newWallet: true, // TODO(mrcyjanek): safe to remove
    restoreHeight: restoreHeight,
  );

  int status = newW.status();

  if (status != 0) {
    final err = newW.errorString();
    printV("err: $err");
    throw WalletRestoreFromKeysException(message: err);
  }

  currentWallet = newW;

  currentWallet!.setCacheAttribute(key: "cakewallet.seed", value: seed);

  storeSync();

  setupBackgroundSync(password, currentWallet!);

  openedWalletsByPath[path] = currentWallet!;
  _lastOpenedWallet = path;
}

String _lastOpenedWallet = "";

Future<void> restoreWalletFromHardwareWallet(
    {required String path,
    required String password,
    required String deviceName,
    int nettype = 0,
    int restoreHeight = 0}) async {
  txhistory = null;
  final wmPtr = MoneroWalletManagerFactory().getWalletManager().ffiAddress();
  final newWptrAddr = await Isolate.run(() {
    return monero.WalletManager_createWalletFromDevice(Pointer.fromAddress(wmPtr),
            path: path, password: password, restoreHeight: restoreHeight, deviceName: deviceName)
        .address;
  });
  final newW = MoneroWallet(Pointer.fromAddress(newWptrAddr));

  final status = newW.status();

  if (status != 0) {
    final error = newW.errorString();
    throw WalletRestoreFromSeedException(message: error);
  }

  currentWallet = newW;
  currentWallet!.store(path: path);
  _lastOpenedWallet = path;
  openedWalletsByPath[path] = currentWallet!;
}

Map<String, Wallet2Wallet> openedWalletsByPath = {};

Future<void> loadWallet({required String path, required String password, int nettype = 0}) async {
  if (openedWalletsByPath[path] != null) {
    txhistory = null;
    currentWallet = openedWalletsByPath[path]!;
    return;
  }
  if (currentWallet == null || path != _lastOpenedWallet) {
    if (currentWallet != null) {
      final addr = currentWallet!.ffiAddress();
      Isolate.run(() {
        monero.Wallet_store(Pointer.fromAddress(addr));
      });
    }
    txhistory = null;

    /// Get the device type
    /// 0: Software Wallet
    /// 1: Ledger
    /// 2: Trezor
    var deviceType = 0;

    if (Platform.isAndroid || Platform.isIOS) {
      deviceType = wmPtr.queryWalletDevice(
        keysFileName: "$path.keys",
        password: password,
        kdfRounds: 1,
      );
      final status = wmPtr.errorString();
      if (status != "") {
        printV("loadWallet:" + status);
        // This is most likely closeWallet call leaking error. This is fine.
        if (status.contains("failed to save file")) {
          printV("loadWallet: error leaked: $status");
          deviceType = 0;
        } else {
          throw WalletOpeningException(message: status);
        }
      }
    } else {
      deviceType = 0;
    }

    if (deviceType == 1) {
      if (gLedger == null) {
        throw Exception("Tried to open a ledger wallet with no ledger connected");
      }
      enableLedgerExchange(gLedger!);
    }

    final addr = wmPtr.ffiAddress();
    final newWptrAddr = await Isolate.run(() {
      return monero.WalletManager_openWallet(Pointer.fromAddress(addr),
              path: path, password: password)
          .address;
    });

    final newW = MoneroWallet(Pointer.fromAddress(newWptrAddr));

    int status = newW.status();
    if (status != 0) {
      final err = newW.errorString();
      printV("loadWallet:" + err);
      throw WalletOpeningException(message: err);
    }
    if (deviceType == 0) {
      setupBackgroundSync(password, newW);
    }

    currentWallet = newW;
    _lastOpenedWallet = path;
    openedWalletsByPath[path] = currentWallet!;
  }
}

void setupBackgroundSync(String password, Wallet2Wallet wallet) {
  if (isViewOnlyBySpendKey(wallet)) {
    return;
  }
  wallet.setupBackgroundSync(
      backgroundSyncType: 2, walletPassword: password, backgroundCachePassword: '');
  if (wallet.status() != 0) {
    // We simply ignore the error.
    printV("setupBackgroundSync: ${wallet.errorString()}");
  }
}

Future<void> openWallet({required String path, required String password, int nettype = 0}) async =>
    loadWallet(path: path, password: password, nettype: nettype);

bool isViewOnlyBySpendKey(Wallet2Wallet? wallet) =>
    int.tryParse((wallet ?? currentWallet!).secretSpendKey()) == 0;
