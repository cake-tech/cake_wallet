import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:cw_monero/convert_utf8_to_string.dart';
import 'package:cw_monero/signatures.dart';
import 'package:cw_monero/types.dart';
import 'package:cw_monero/monero_api.dart';
import 'package:cw_monero/exceptions/setup_wallet_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

int _boolToInt(bool value) => value ? 1 : 0;

final getFileNameNative = moneroApi
    .lookup<NativeFunction<get_filename>>('get_filename')
    .asFunction<GetFilename>();

final getSeedNative =
    moneroApi.lookup<NativeFunction<get_seed>>('seed').asFunction<GetSeed>();

final getAddressNative = moneroApi
    .lookup<NativeFunction<get_address>>('get_address')
    .asFunction<GetAddress>();

final getFullBalanceNative = moneroApi
    .lookup<NativeFunction<get_full_balanace>>('get_full_balance')
    .asFunction<GetFullBalance>();

final getUnlockedBalanceNative = moneroApi
    .lookup<NativeFunction<get_unlocked_balanace>>('get_unlocked_balance')
    .asFunction<GetUnlockedBalance>();

final getCurrentHeightNative = moneroApi
    .lookup<NativeFunction<get_current_height>>('get_current_height')
    .asFunction<GetCurrentHeight>();

final getNodeHeightNative = moneroApi
    .lookup<NativeFunction<get_node_height>>('get_node_height')
    .asFunction<GetNodeHeight>();

final isConnectedNative = moneroApi
    .lookup<NativeFunction<is_connected>>('is_connected')
    .asFunction<IsConnected>();

final setupNodeNative = moneroApi
    .lookup<NativeFunction<setup_node>>('setup_node')
    .asFunction<SetupNode>();

final startRefreshNative = moneroApi
    .lookup<NativeFunction<start_refresh>>('start_refresh')
    .asFunction<StartRefresh>();

final connecToNodeNative = moneroApi
    .lookup<NativeFunction<connect_to_node>>('connect_to_node')
    .asFunction<ConnectToNode>();

final setRefreshFromBlockHeightNative = moneroApi
    .lookup<NativeFunction<set_refresh_from_block_height>>(
        'set_refresh_from_block_height')
    .asFunction<SetRefreshFromBlockHeight>();

final setRecoveringFromSeedNative = moneroApi
    .lookup<NativeFunction<set_recovering_from_seed>>(
        'set_recovering_from_seed')
    .asFunction<SetRecoveringFromSeed>();

final storeNative =
    moneroApi.lookup<NativeFunction<store_c>>('store').asFunction<Store>();

final setListenerNative = moneroApi
    .lookup<NativeFunction<set_listener>>('set_listener')
    .asFunction<SetListener>();

final getSyncingHeightNative = moneroApi
    .lookup<NativeFunction<get_syncing_height>>('get_syncing_height')
    .asFunction<GetSyncingHeight>();

final isNeededToRefreshNative = moneroApi
    .lookup<NativeFunction<is_needed_to_refresh>>('is_needed_to_refresh')
    .asFunction<IsNeededToRefresh>();

final isNewTransactionExistNative = moneroApi
    .lookup<NativeFunction<is_new_transaction_exist>>(
        'is_new_transaction_exist')
    .asFunction<IsNewTransactionExist>();

final getSecretViewKeyNative = moneroApi
    .lookup<NativeFunction<secret_view_key>>('secret_view_key')
    .asFunction<SecretViewKey>();

final getPublicViewKeyNative = moneroApi
    .lookup<NativeFunction<public_view_key>>('public_view_key')
    .asFunction<PublicViewKey>();

final getSecretSpendKeyNative = moneroApi
    .lookup<NativeFunction<secret_spend_key>>('secret_spend_key')
    .asFunction<SecretSpendKey>();

final getPublicSpendKeyNative = moneroApi
    .lookup<NativeFunction<secret_view_key>>('public_spend_key')
    .asFunction<PublicSpendKey>();

final closeCurrentWalletNative = moneroApi
    .lookup<NativeFunction<close_current_wallet>>('close_current_wallet')
    .asFunction<CloseCurrentWallet>();

final onStartupNative = moneroApi
    .lookup<NativeFunction<on_startup>>('on_startup')
    .asFunction<OnStartup>();

final rescanBlockchainAsyncNative = moneroApi
    .lookup<NativeFunction<rescan_blockchain>>('rescan_blockchain')
    .asFunction<RescanBlockchainAsync>();

int getSyncingHeight() => getSyncingHeightNative();

bool isNeededToRefresh() => isNeededToRefreshNative() != 0;

bool isNewTransactionExist() => isNewTransactionExistNative() != 0;

String getFilename() => convertUTF8ToString(pointer: getFileNameNative());

String getSeed() => convertUTF8ToString(pointer: getSeedNative());

String getAddress({int accountIndex = 0, int addressIndex = 0}) =>
    convertUTF8ToString(pointer: getAddressNative(accountIndex, addressIndex));

int getFullBalance({int accountIndex = 0}) =>
    getFullBalanceNative(accountIndex);

int getUnlockedBalance({int accountIndex = 0}) =>
    getUnlockedBalanceNative(accountIndex);

int getCurrentHeight() => getCurrentHeightNative();

int getNodeHeightSync() => getNodeHeightNative();

bool isConnectedSync() => isConnectedNative() != 0;

bool setupNodeSync(
    {String address,
    String login,
    String password,
    bool useSSL = false,
    bool isLightWallet = false}) {
  final addressPointer = Utf8.toUtf8(address);
  Pointer<Utf8> loginPointer;
  Pointer<Utf8> passwordPointer;

  if (login != null) {
    loginPointer = Utf8.toUtf8(login);
  }

  if (password != null) {
    passwordPointer = Utf8.toUtf8(password);
  }

  final errorMessagePointer = allocate<Utf8>();
  final isSetupNode = setupNodeNative(
          addressPointer,
          loginPointer,
          passwordPointer,
          _boolToInt(useSSL),
          _boolToInt(isLightWallet),
          errorMessagePointer) !=
      0;

  free(addressPointer);
  free(loginPointer);
  free(passwordPointer);

  if (!isSetupNode) {
    throw SetupWalletException(
        message: convertUTF8ToString(pointer: errorMessagePointer));
  }

  return isSetupNode;
}

void startRefreshSync() => startRefreshNative();

Future<bool> connectToNode() async => connecToNodeNative() != 0;

void setRefreshFromBlockHeight({int height}) =>
    setRefreshFromBlockHeightNative(height);

void setRecoveringFromSeed({bool isRecovery}) =>
    setRecoveringFromSeedNative(_boolToInt(isRecovery));

void storeSync() {
  final pathPointer = Utf8.toUtf8('');
  storeNative(pathPointer);
  free(pathPointer);
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

  Timer _updateSyncInfoTimer;
  int _cachedBlockchainHeight;
  int _lastKnownBlockHeight;
  int _initialSyncHeight;

  Future<int> getNodeHeightOrUpdate(int baseHeight) async {
    if (_cachedBlockchainHeight < baseHeight || _cachedBlockchainHeight == 0) {
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
        onNewTransaction?.call();
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
      final track = bchHeight - _initialSyncHeight;
      final diff = track - (bchHeight - syncHeight);
      final ptc = diff <= 0 ? 0.0 : diff / track;
      final left = bchHeight - syncHeight;

      if (syncHeight < 0 || left < 0) {
        return;
      }

      // 1. Actual new height; 2. Blocks left to finish; 3. Progress in percents;
      onNewBlock?.call(syncHeight, left, ptc);
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
        {String address,
        String login,
        String password,
        bool useSSL = false,
        bool isLightWallet = false}) =>
    compute<Map<String, Object>, void>(_setupNodeSync, {
      'address': address,
      'login': login,
      'password': password,
      'useSSL': useSSL,
      'isLightWallet': isLightWallet
    });

Future store() => compute<int, void>(_storeSync, 0);

Future<bool> isConnected() => compute(_isConnected, 0);

Future<int> getNodeHeight() => compute(_getNodeHeight, 0);

void rescanBlockchainAsync() => rescanBlockchainAsyncNative();
