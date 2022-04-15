import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_haven/api/convert_utf8_to_string.dart';
import 'package:cw_haven/api/signatures.dart';
import 'package:cw_haven/api/types.dart';
import 'package:cw_haven/api/haven_api.dart';
import 'package:cw_haven/api/wallet.dart';
import 'package:cw_haven/api/exceptions/wallet_opening_exception.dart';
import 'package:cw_haven/api/exceptions/wallet_creation_exception.dart';
import 'package:cw_haven/api/exceptions/wallet_restore_from_keys_exception.dart';
import 'package:cw_haven/api/exceptions/wallet_restore_from_seed_exception.dart';

final createWalletNative = havenApi
    .lookup<NativeFunction<create_wallet>>('create_wallet')
    .asFunction<CreateWallet>();

final restoreWalletFromSeedNative = havenApi
    .lookup<NativeFunction<restore_wallet_from_seed>>(
        'restore_wallet_from_seed')
    .asFunction<RestoreWalletFromSeed>();

final restoreWalletFromKeysNative = havenApi
    .lookup<NativeFunction<restore_wallet_from_keys>>(
        'restore_wallet_from_keys')
    .asFunction<RestoreWalletFromKeys>();

final isWalletExistNative = havenApi
    .lookup<NativeFunction<is_wallet_exist>>('is_wallet_exist')
    .asFunction<IsWalletExist>();

final loadWalletNative = havenApi
    .lookup<NativeFunction<load_wallet>>('load_wallet')
    .asFunction<LoadWallet>();

final errorStringNative = havenApi
    .lookup<NativeFunction<error_string>>('error_string')
    .asFunction<ErrorString>();

void createWalletSync(
    {String path, String password, String language, int nettype = 0}) {
  final pathPointer = Utf8.toUtf8(path);
  final passwordPointer = Utf8.toUtf8(password);
  final languagePointer = Utf8.toUtf8(language);
  final errorMessagePointer = allocate<Utf8>();
  final isWalletCreated = createWalletNative(pathPointer, passwordPointer,
          languagePointer, nettype, errorMessagePointer) !=
      0;

  free(pathPointer);
  free(passwordPointer);
  free(languagePointer);

  if (!isWalletCreated) {
    throw WalletCreationException(
        message: convertUTF8ToString(pointer: errorMessagePointer));
  }

  // setupNodeSync(address: "node.moneroworld.com:18089");
}

bool isWalletExistSync({String path}) {
  final pathPointer = Utf8.toUtf8(path);
  final isExist = isWalletExistNative(pathPointer) != 0;

  free(pathPointer);

  return isExist;
}

void restoreWalletFromSeedSync(
    {String path,
    String password,
    String seed,
    int nettype = 0,
    int restoreHeight = 0}) {
  final pathPointer = Utf8.toUtf8(path);
  final passwordPointer = Utf8.toUtf8(password);
  final seedPointer = Utf8.toUtf8(seed);
  final errorMessagePointer = allocate<Utf8>();
  final isWalletRestored = restoreWalletFromSeedNative(
          pathPointer,
          passwordPointer,
          seedPointer,
          nettype,
          restoreHeight,
          errorMessagePointer) !=
      0;

  free(pathPointer);
  free(passwordPointer);
  free(seedPointer);

  if (!isWalletRestored) {
    throw WalletRestoreFromSeedException(
        message: convertUTF8ToString(pointer: errorMessagePointer));
  }
}

void restoreWalletFromKeysSync(
    {String path,
    String password,
    String language,
    String address,
    String viewKey,
    String spendKey,
    int nettype = 0,
    int restoreHeight = 0}) {
  final pathPointer = Utf8.toUtf8(path);
  final passwordPointer = Utf8.toUtf8(password);
  final languagePointer = Utf8.toUtf8(language);
  final addressPointer = Utf8.toUtf8(address);
  final viewKeyPointer = Utf8.toUtf8(viewKey);
  final spendKeyPointer = Utf8.toUtf8(spendKey);
  final errorMessagePointer = allocate<Utf8>();
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

  free(pathPointer);
  free(passwordPointer);
  free(languagePointer);
  free(addressPointer);
  free(viewKeyPointer);
  free(spendKeyPointer);

  if (!isWalletRestored) {
    throw WalletRestoreFromKeysException(
        message: convertUTF8ToString(pointer: errorMessagePointer));
  }
}

void loadWallet({String path, String password, int nettype = 0}) {
  final pathPointer = Utf8.toUtf8(path);
  final passwordPointer = Utf8.toUtf8(password);
  final loaded = loadWalletNative(pathPointer, passwordPointer, nettype) != 0;
  free(pathPointer);
  free(passwordPointer);

  if (!loaded) {
    throw WalletOpeningException(
        message: convertUTF8ToString(pointer: errorStringNative()));
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

Future<void> _openWallet(Map<String, String> args) async =>
    loadWallet(path: args['path'], password: args['password']);

bool _isWalletExist(String path) => isWalletExistSync(path: path);

void openWallet({String path, String password, int nettype = 0}) async =>
    loadWallet(path: path, password: password, nettype: nettype);

Future<void> openWalletAsync(Map<String, String> args) async =>
    compute(_openWallet, args);

Future<void> createWallet(
        {String path,
        String password,
        String language,
        int nettype = 0}) async =>
    compute(_createWallet, {
      'path': path,
      'password': password,
      'language': language,
      'nettype': nettype
    });

Future restoreFromSeed(
        {String path,
        String password,
        String seed,
        int nettype = 0,
        int restoreHeight = 0}) async =>
    compute<Map<String, Object>, void>(_restoreFromSeed, {
      'path': path,
      'password': password,
      'seed': seed,
      'nettype': nettype,
      'restoreHeight': restoreHeight
    });

Future restoreFromKeys(
        {String path,
        String password,
        String language,
        String address,
        String viewKey,
        String spendKey,
        int nettype = 0,
        int restoreHeight = 0}) async =>
    compute<Map<String, Object>, void>(_restoreFromKeys, {
      'path': path,
      'password': password,
      'language': language,
      'address': address,
      'viewKey': viewKey,
      'spendKey': spendKey,
      'nettype': nettype,
      'restoreHeight': restoreHeight
    });

Future<bool> isWalletExist({String path}) => compute(_isWalletExist, path);
