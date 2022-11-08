import 'dart:ffi';

import 'package:cw_wownero/api/convert_utf8_to_string.dart';
import 'package:cw_wownero/api/exceptions/wallet_creation_exception.dart';
import 'package:cw_wownero/api/exceptions/wallet_opening_exception.dart';
import 'package:cw_wownero/api/exceptions/wallet_restore_from_keys_exception.dart';
import 'package:cw_wownero/api/exceptions/wallet_restore_from_seed_exception.dart';
import 'package:cw_wownero/api/signatures.dart';
import 'package:cw_wownero/api/types.dart';
import 'package:cw_wownero/api/wownero_api.dart';
import 'package:ffi/ffi.dart';
import 'package:ffi/ffi.dart' as pkgffi;
import 'package:flutter/foundation.dart';

final create14WordWalletNative = wowneroApi
    .lookup<NativeFunction<create_14_word_wallet>>('create_14_word_wallet')
    .asFunction<Create14WordWallet>();

final create25WordWalletNative = wowneroApi
    .lookup<NativeFunction<create_25_word_wallet>>('create_25_word_wallet')
    .asFunction<Create25WordWallet>();

final restoreWalletFrom14WordSeedNative = wowneroApi
    .lookup<NativeFunction<restore_wallet_from_14_word_seed>>(
        'restore_wallet_from_14_word_seed')
    .asFunction<RestoreWalletFrom14WordSeed>();

final restoreWalletFrom25WordSeedNative = wowneroApi
    .lookup<NativeFunction<restore_wallet_from_25_word_seed>>(
        'restore_wallet_from_25_word_seed')
    .asFunction<RestoreWalletFrom25WordSeed>();

final restoreWalletFromKeysNative = wowneroApi
    .lookup<NativeFunction<restore_wallet_from_keys>>(
        'restore_wallet_from_keys')
    .asFunction<RestoreWalletFromKeys>();

final isWalletExistNative = wowneroApi
    .lookup<NativeFunction<is_wallet_exist>>('is_wallet_exist')
    .asFunction<IsWalletExist>();

final loadWalletNative = wowneroApi
    .lookup<NativeFunction<load_wallet>>('load_wallet')
    .asFunction<LoadWallet>();

final errorStringNative = wowneroApi
    .lookup<NativeFunction<error_string>>('error_string')
    .asFunction<ErrorString>();

void createWalletSync(
    {required String path,
    required String password,
    required String language,
    int nettype = 0,
    int seedWordsLength = 14}) {
  final pathPointer = path.toNativeUtf8();
  final passwordPointer = password.toNativeUtf8();
  final languagePointer = language.toNativeUtf8();
  final errorMessagePointer =
      pkgffi.calloc.allocate<Utf8>(sizeOf<Pointer<Utf8>>());

  bool
      isWalletCreated; // TODO refactor to return to use of final isWalletCreated
  if (seedWordsLength == 14) {
    isWalletCreated = create14WordWalletNative(pathPointer, passwordPointer,
            languagePointer, nettype, errorMessagePointer) !=
        0;
  } else /*if (seedWordsLength == 25)*/ {
    isWalletCreated = create25WordWalletNative(pathPointer, passwordPointer,
            languagePointer, nettype, errorMessagePointer) !=
        0;
    // TODO handle other cases / validation
  }

  pkgffi.calloc.free(pathPointer);
  pkgffi.calloc.free(passwordPointer);
  pkgffi.calloc.free(languagePointer);

  if (!isWalletCreated) {
    throw WalletCreationException(
        message: convertUTF8ToString(pointer: errorMessagePointer));
  }

  // setupNodeSync(address: "node.moneroworld.com:18089");
}

bool isWalletExistSync({required String path}) {
  final pathPointer = path.toNativeUtf8();
  final isExist = isWalletExistNative(pathPointer) != 0;

  pkgffi.calloc.free(pathPointer);

  return isExist;
}

void restoreWalletFromSeedSync(
    {required String path,
    required String password,
    required String seed,
    int nettype = 0,
    int? restoreHeight = 0}) {
  final pathPointer = path.toNativeUtf8();
  final passwordPointer = password.toNativeUtf8();
  final seedPointer = seed.toNativeUtf8();
  final errorMessagePointer =
      pkgffi.calloc.allocate<Utf8>(sizeOf<Pointer<Utf8>>());

  int seedWordsLength = seed.split(' ').length;
  bool isWalletRestored; // TODO refactor to return to use of final isRestored
  if (seedWordsLength == 14) {
    isWalletRestored = restoreWalletFrom14WordSeedNative(pathPointer,
            passwordPointer, seedPointer, nettype, errorMessagePointer) !=
        0;
  } else /*if(seedWordsLength == 25)*/ {
    isWalletRestored = restoreWalletFrom25WordSeedNative(pathPointer,
            passwordPointer, seedPointer, nettype, errorMessagePointer) !=
        0;
    // TODO handle other cases / validation
  }

  pkgffi.calloc.free(pathPointer);
  pkgffi.calloc.free(passwordPointer);
  pkgffi.calloc.free(seedPointer);

  if (!isWalletRestored) {
    throw WalletRestoreFromSeedException(
        message: convertUTF8ToString(pointer: errorMessagePointer));
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
    int? restoreHeight = 0}) {
  final pathPointer = path.toNativeUtf8();
  final passwordPointer = password.toNativeUtf8();
  final languagePointer = language.toNativeUtf8();
  final addressPointer = address.toNativeUtf8();
  final viewKeyPointer = viewKey.toNativeUtf8();
  final spendKeyPointer = spendKey.toNativeUtf8();
  final errorMessagePointer =
      pkgffi.calloc.allocate<Utf8>(sizeOf<Pointer<Utf8>>());
  final isWalletRestored = restoreWalletFromKeysNative(
          pathPointer,
          passwordPointer,
          languagePointer,
          addressPointer,
          viewKeyPointer,
          spendKeyPointer,
          nettype,
          restoreHeight,
          errorMessagePointer) !=
      0;

  pkgffi.calloc.free(pathPointer);
  pkgffi.calloc.free(passwordPointer);
  pkgffi.calloc.free(languagePointer);
  pkgffi.calloc.free(addressPointer);
  pkgffi.calloc.free(viewKeyPointer);
  pkgffi.calloc.free(spendKeyPointer);

  if (!isWalletRestored) {
    throw WalletRestoreFromKeysException(
        message: convertUTF8ToString(pointer: errorMessagePointer));
  }
}

void loadWallet(
    {required String path, required String password, int nettype = 0}) {
  final pathPointer = path.toNativeUtf8();
  final passwordPointer = password.toNativeUtf8();
  final loaded = loadWalletNative(pathPointer, passwordPointer, nettype) != 0;
  pkgffi.calloc.free(pathPointer);
  pkgffi.calloc.free(passwordPointer);

  if (!loaded) {
    throw WalletOpeningException(
        message: convertUTF8ToString(pointer: errorStringNative()));
  }
}

void _createWallet(Map<String, dynamic> args) {
  final path = args['path'] as String;
  final password = args['password'] as String;
  final language = args['language'] as String;
  final seedWordsLength = args['seedWordsLength'] as int?;

  createWalletSync(
      path: path,
      password: password,
      language: language,
      seedWordsLength: seedWordsLength ?? 14);
}

void _restoreFromSeed(Map<String, dynamic> args) {
  final path = args['path'] as String;
  final password = args['password'] as String;
  final seed = args['seed'] as String;
  final restoreHeight = args['restoreHeight'] as int?;

  restoreWalletFromSeedSync(
      path: path, password: password, seed: seed, restoreHeight: restoreHeight);
}

void _restoreFromKeys(Map<String, dynamic> args) {
  final path = args['path'] as String;
  final password = args['password'] as String;
  final language = args['language'] as String;
  final restoreHeight = args['restoreHeight'] as int?;
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

Future<void> _openWallet(Map<String, String> args) async =>
    loadWallet(path: args['path']!, password: args['password']!);

bool _isWalletExist(String? path) => isWalletExistSync(path: path!);

void openWallet(
        {required String path,
        required String password,
        int nettype = 0}) async =>
    loadWallet(path: path, password: password, nettype: nettype);

Future<void> openWalletAsync(Map<String, String> args) async =>
    compute(_openWallet, args);

Future<void> createWallet(
        {String? path,
        String? password,
        String? language,
        int nettype = 0,
        int seedWordsLength = 14}) async =>
    compute(_createWallet, {
      'path': path,
      'password': password,
      'language': language,
      'nettype': nettype,
      'seedWordsLength': seedWordsLength
    });

Future restoreFromSeed(
        {String? path,
        String? password,
        String? seed,
        int nettype = 0,
        int? restoreHeight = 0}) async =>
    compute<Map<String, Object?>, void>(_restoreFromSeed, {
      'path': path,
      'password': password,
      'seed': seed,
      'nettype': nettype,
      'restoreHeight': restoreHeight
    });

Future restoreFromKeys(
        {String? path,
        String? password,
        String? language,
        String? address,
        String? viewKey,
        String? spendKey,
        int nettype = 0,
        int? restoreHeight = 0}) async =>
    compute<Map<String, Object?>, void>(_restoreFromKeys, {
      'path': path,
      'password': password,
      'language': language,
      'address': address,
      'viewKey': viewKey,
      'spendKey': spendKey,
      'nettype': nettype,
      'restoreHeight': restoreHeight
    });

Future<bool> isWalletExist({String? path}) => compute(_isWalletExist, path);
