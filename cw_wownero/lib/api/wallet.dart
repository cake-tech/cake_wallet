import 'dart:async';
import 'dart:ffi';

import 'package:cw_wownero/api/convert_utf8_to_string.dart';
import 'package:cw_wownero/api/exceptions/setup_wallet_exception.dart';
import 'package:cw_wownero/api/signatures.dart';
import 'package:cw_wownero/api/structs/ut8_box.dart';
import 'package:cw_wownero/api/types.dart';
import 'package:cw_wownero/api/wownero_api.dart';
import 'package:ffi/ffi.dart';
import 'package:ffi/ffi.dart' as pkgffi;
import 'package:flutter/foundation.dart';

int _boolToInt(bool value) => value ? 1 : 0;

final getFileNameNative = wowneroApi
    .lookup<NativeFunction<wow_get_filename>>('wow_get_filename')
    .asFunction<GetFilename>();

final getSeedNative = wowneroApi
    .lookup<NativeFunction<wow_get_seed>>('wow_seed')
    .asFunction<GetSeed>();

final getAddressNative = wowneroApi
    .lookup<NativeFunction<wow_get_address>>('wow_get_address')
    .asFunction<GetAddress>();

final getFullBalanceNative = wowneroApi
    .lookup<NativeFunction<wow_get_full_balance>>('wow_get_full_balance')
    .asFunction<GetFullBalance>();

final getUnlockedBalanceNative = wowneroApi
    .lookup<NativeFunction<wow_get_unlocked_balance>>('wow_get_unlocked_balance')
    .asFunction<GetUnlockedBalance>();

final getCurrentHeightNative = wowneroApi
    .lookup<NativeFunction<wow_get_current_height>>('wow_get_current_height')
    .asFunction<GetCurrentHeight>();

final getNodeHeightNative = wowneroApi
    .lookup<NativeFunction<wow_get_node_height>>('wow_get_node_height')
    .asFunction<GetNodeHeight>();

final getSeedHeightNative = wowneroApi
    .lookup<NativeFunction<wow_get_seed_height>>('wow_get_seed_height')
    .asFunction<GetSeedHeight>();

final isConnectedNative = wowneroApi
    .lookup<NativeFunction<wow_is_connected>>('wow_is_connected')
    .asFunction<IsConnected>();

final setupNodeNative = wowneroApi
    .lookup<NativeFunction<wow_setup_node>>('wow_setup_node')
    .asFunction<SetupNode>();

final startRefreshNative = wowneroApi
    .lookup<NativeFunction<wow_start_refresh>>('wow_start_refresh')
    .asFunction<StartRefresh>();

final connecToNodeNative = wowneroApi
    .lookup<NativeFunction<wow_connect_to_node>>('wow_connect_to_node')
    .asFunction<ConnectToNode>();

final setRefreshFromBlockHeightNative = wowneroApi
    .lookup<NativeFunction<wow_set_refresh_from_block_height>>(
        'wow_set_refresh_from_block_height')
    .asFunction<SetRefreshFromBlockHeight>();

final setRecoveringFromSeedNative = wowneroApi
    .lookup<NativeFunction<wow_set_recovering_from_seed>>(
        'wow_set_recovering_from_seed')
    .asFunction<SetRecoveringFromSeed>();

final storeNative = wowneroApi
    .lookup<NativeFunction<wow_store_c>>('wow_store')
    .asFunction<Store>();

final setPasswordNative = wowneroApi
    .lookup<NativeFunction<wow_set_password>>('wow_set_password')
    .asFunction<SetPassword>();

final setListenerNative = wowneroApi
    .lookup<NativeFunction<wow_set_listener>>('wow_set_listener')
    .asFunction<SetListener>();

final getSyncingHeightNative = wowneroApi
    .lookup<NativeFunction<wow_get_syncing_height>>('wow_get_syncing_height')
    .asFunction<GetSyncingHeight>();

final isNeededToRefreshNative = wowneroApi
    .lookup<NativeFunction<wow_is_needed_to_refresh>>('wow_is_needed_to_refresh')
    .asFunction<IsNeededToRefresh>();

final isNewTransactionExistNative = wowneroApi
    .lookup<NativeFunction<wow_is_new_transaction_exist>>(
        'wow_is_new_transaction_exist')
    .asFunction<IsNewTransactionExist>();

final getSecretViewKeyNative = wowneroApi
    .lookup<NativeFunction<wow_secret_view_key>>('wow_secret_view_key')
    .asFunction<SecretViewKey>();

final getPublicViewKeyNative = wowneroApi
    .lookup<NativeFunction<wow_public_view_key>>('wow_public_view_key')
    .asFunction<PublicViewKey>();

final getSecretSpendKeyNative = wowneroApi
    .lookup<NativeFunction<wow_secret_spend_key>>('wow_secret_spend_key')
    .asFunction<SecretSpendKey>();

final getPublicSpendKeyNative = wowneroApi
    .lookup<NativeFunction<wow_public_spend_key>>('wow_public_spend_key')
    .asFunction<PublicSpendKey>();

final closeCurrentWalletNative = wowneroApi
    .lookup<NativeFunction<wow_close_current_wallet>>(
        'wow_close_current_wallet')
    .asFunction<CloseCurrentWallet>();

final onStartupNative = wowneroApi
    .lookup<NativeFunction<wow_on_startup>>('wow_on_startup')
    .asFunction<OnStartup>();

final rescanBlockchainAsyncNative = wowneroApi
    .lookup<NativeFunction<wow_rescan_blockchain>>('wow_rescan_blockchain')
    .asFunction<RescanBlockchainAsync>();

final getSubaddressLabelNative = wowneroApi
    .lookup<NativeFunction<wow_get_subaddress_label>>('wow_get_subaddress_label')
    .asFunction<GetSubaddressLabel>();

final validateAddressNative = wowneroApi
    .lookup<NativeFunction<wow_validate_address>>('wow_validate_address')
    .asFunction<ValidateAddress>();

int getSyncingHeight() => getSyncingHeightNative();

bool isNeededToRefresh() => isNeededToRefreshNative() != 0;

bool isNewTransactionExist() => isNewTransactionExistNative() != 0;

String getFilename() => convertUTF8ToString(pointer: getFileNameNative());

String getSeed() => convertUTF8ToString(pointer: getSeedNative());

String getAddress({int accountIndex = 0, int addressIndex = 0}) =>
    convertUTF8ToString(pointer: getAddressNative(accountIndex, addressIndex));

int getFullBalance({int? accountIndex = 0}) =>
    getFullBalanceNative(accountIndex);

int getUnlockedBalance({int? accountIndex = 0}) =>
    getUnlockedBalanceNative(accountIndex);

int getCurrentHeight() => getCurrentHeightNative();

int getNodeHeightSync() => getNodeHeightNative();

int getSeedHeightSync(String seed) {
  final seedPointer = seed.toNativeUtf8();
  final ret = getSeedHeightNative(seedPointer);
  pkgffi.calloc.free(seedPointer);
  return ret;
}

bool isConnectedSync() => isConnectedNative() != 0;

bool setupNodeSync(
    {required String address,
    String? login,
    String? password,
    bool useSSL = false,
    bool isLightWallet = false}) {
  print("SetupNodeSync begin");
  final addressPointer = address.toNativeUtf8();
  Pointer<Utf8>? loginPointer;
  Pointer<Utf8>? passwordPointer;

  if (login != null) {
    loginPointer = login.toNativeUtf8();
  }

  if (password != null) {
    passwordPointer = password.toNativeUtf8();
  }

  final errorMessagePointer =
      pkgffi.calloc.allocate<Utf8>(sizeOf<Pointer<Utf8>>());
  final isSetupNode = setupNodeNative(
          addressPointer,
          loginPointer!,
          passwordPointer!,
          _boolToInt(useSSL),
          _boolToInt(isLightWallet),
          errorMessagePointer) !=
      0;

  pkgffi.calloc.free(addressPointer);
  pkgffi.calloc.free(loginPointer);
  pkgffi.calloc.free(passwordPointer);

  if (!isSetupNode) {
    throw SetupWalletException(
        message: convertUTF8ToString(pointer: errorMessagePointer));
  }
  print("setup nodesync end");

  return isSetupNode;
}

void startRefreshSync() => startRefreshNative();

Future<bool> connectToNode() async => connecToNodeNative() != 0;

void setRefreshFromBlockHeight({int? height = 0}) =>
    setRefreshFromBlockHeightNative(height ?? 0);

void setRecoveringFromSeed({required bool isRecovery}) =>
    setRecoveringFromSeedNative(_boolToInt(isRecovery));

void storeSync() {
  final pathPointer = ''.toNativeUtf8();
  storeNative(pathPointer);
  pkgffi.calloc.free(pathPointer);
}

void setPasswordSync(String password) {
  final passwordPointer = password.toNativeUtf8();
  final errorMessagePointer =
      pkgffi.calloc.allocate<Utf8Box>(sizeOf<Utf8Box>());
  // final errorMessagePointer = allocate<Utf8Box>();
  final changed = setPasswordNative(passwordPointer, errorMessagePointer) != 0;
  pkgffi.calloc.free(passwordPointer);

  if (!changed) {
    final message = errorMessagePointer.ref.getValue();
    pkgffi.calloc.free(errorMessagePointer);
    throw Exception(message);
  }

  pkgffi.calloc.free(errorMessagePointer);
}

void closeCurrentWallet() => closeCurrentWalletNative();

String getSecretViewKey() =>
    convertUTF8ToString(pointer: getSecretViewKeyNative());

String getPublicViewKey() =>
    convertUTF8ToString(pointer: getPublicViewKeyNative());

String getSecretSpendKey() =>
    convertUTF8ToString(pointer: getSecretSpendKeyNative());

String getPublicSpendKey() =>
    convertUTF8ToString(pointer: getPublicSpendKeyNative());

class SyncListener {
  SyncListener(this.onNewBlock, this.onNewTransaction) {
    _cachedBlockchainHeight = 0;
    _lastKnownBlockHeight = 0;
    _initialSyncHeight = 0;
  }

  void Function(int, int, double) onNewBlock;
  void Function() onNewTransaction;

  Timer? _updateSyncInfoTimer;
  int? _cachedBlockchainHeight;
  int? _lastKnownBlockHeight;
  late int _initialSyncHeight;

  Future<int?> getNodeHeightOrUpdate(int baseHeight) async {
    if (_cachedBlockchainHeight! < baseHeight || _cachedBlockchainHeight == 0) {
      _cachedBlockchainHeight = await getNodeHeight();
    }

    return _cachedBlockchainHeight;
  }

  void start() {
    _cachedBlockchainHeight = 0;
    _lastKnownBlockHeight = 0;
    _initialSyncHeight = 0;
    _updateSyncInfoTimer ??=
        Timer.periodic(Duration(milliseconds: 1200), (_) async {
      if (isNewTransactionExist()) {
        onNewTransaction.call();
      }

      var syncHeight = getSyncingHeight();

      if (syncHeight <= 0) {
        syncHeight = getCurrentHeight();
      }

      if (_initialSyncHeight <= 0) {
        _initialSyncHeight = syncHeight;
      }

      final bchHeight = await getNodeHeightOrUpdate(syncHeight);

      if (_lastKnownBlockHeight == syncHeight || syncHeight == null) {
        return;
      }

      _lastKnownBlockHeight = syncHeight;
      final track = bchHeight! - _initialSyncHeight;
      final diff = track - (bchHeight - syncHeight);
      final ptc = diff <= 0 ? 0.0 : diff / track;
      final left = bchHeight - syncHeight;

      if (syncHeight < 0 || left < 0) {
        return;
      }

      // 1. Actual new height; 2. Blocks left to finish; 3. Progress in percents;
      onNewBlock.call(syncHeight, left, ptc);
    });
  }

  void stop() => _updateSyncInfoTimer?.cancel();
}

SyncListener setListeners(void Function(int, int, double) onNewBlock,
    void Function() onNewTransaction) {
  final listener = SyncListener(onNewBlock, onNewTransaction);
  setListenerNative();
  return listener;
}

void onStartup() => onStartupNative();

void _storeSync(Object _) => storeSync();

bool _setupNodeSync(Map args) {
  final address = args['address'] as String;
  final login = (args['login'] ?? '') as String;
  final password = (args['password'] ?? '') as String;
  final useSSL = args['useSSL'] as bool;
  final isLightWallet = args['isLightWallet'] as bool;

  return setupNodeSync(
      address: address,
      login: login,
      password: password,
      useSSL: useSSL,
      isLightWallet: isLightWallet);
}

bool _isConnected(Object _) => isConnectedSync();

int _getNodeHeight(Object _) => getNodeHeightSync();

void startRefresh() => startRefreshSync();

Future setupNode(
        {String? address,
        String? login,
        String? password,
        bool useSSL = false,
        bool isLightWallet = false}) =>
    compute<Map<String, Object?>, void>(_setupNodeSync, {
      'address': address,
      'login': login,
      'password': password,
      'useSSL': useSSL,
      'isLightWallet': isLightWallet
    });

int storeTime = 0;
bool priorityInQueue = false;

Future<bool> store({bool prioritySave = false}) async {
  if (priorityInQueue) {
    return false;
  }
  print(
      "${DateTime.now().millisecondsSinceEpoch} $prioritySave $priorityInQueue");
  if (DateTime.now().millisecondsSinceEpoch < storeTime + 90000 &&
      prioritySave) {
    priorityInQueue = true;
    await Future.delayed(Duration(seconds: 1));
    priorityInQueue = false;
    return store(prioritySave: prioritySave);
  } else if (DateTime.now().millisecondsSinceEpoch < storeTime + 90000 &&
      !prioritySave) {
    return false;
  }
  print("released $storeTime");
  storeTime = DateTime.now().millisecondsSinceEpoch;
  await compute<int, void>(_storeSync, 0);
  return true;
}

Future<bool> isConnected() => compute(_isConnected, 0);

Future<int> getNodeHeight() => compute(_getNodeHeight, 0);

void rescanBlockchainAsync() => rescanBlockchainAsyncNative();

String getSubaddressLabel(int accountIndex, int addressIndex) {
  return convertUTF8ToString(
      pointer: getSubaddressLabelNative(accountIndex, addressIndex));
}

bool validateAddress(String address) {
  final addressPointer = address.toNativeUtf8();
  final valid = validateAddressNative(addressPointer) != 0;
  pkgffi.calloc.free(addressPointer);
  return valid;
}
