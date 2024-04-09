import 'dart:ffi';

import 'package:cw_zano/api/utf8_box.dart';
import 'package:cw_zano/api/zano_api.dart';
import 'package:ffi/ffi.dart';

// char * create_wallet(char *path, char *password, char *language, int32_t networkType, char *error)
typedef _create_wallet = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32, Pointer<Utf8>);
typedef _CreateWallet = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int, Pointer<Utf8>);

// char * restore_wallet_from_seed(char *path, char *password, char *seed, int32_t networkType, uint64_t restoreHeight, char *error)
typedef _restore_wallet_from_seed = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32, Int64, Pointer<Utf8>);
typedef _RestoreWalletFromSeed = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int, int, Pointer<Utf8>);

// char * load_wallet(char *path, char *password, int32_t nettype)
typedef _load_wallet = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Int8);
typedef _LoadWallet = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, int);

// is_wallet_exist(char *path)
typedef _is_wallet_exist = Int8 Function(Pointer<Utf8>);
typedef _IsWalletExist = int Function(Pointer<Utf8>);

// void close_wallet(uint64_t hwallet)
// char *close_wallet(uint64_t hwallet)
typedef _close_wallet = Pointer<Utf8> Function(Int64);
typedef _closeWallet = Pointer<Utf8> Function(int hWallet);

// uint64_t get_current_tx_fee(uint64_t priority)
typedef _get_current_tx_fee = Int64 Function(Int64);
typedef _getCurrentTxFee = int Function(int priority);

// char* get_address_info(char* address)
typedef _GetAddressInfo = Pointer<Utf8> Function(Pointer<Utf8> address);

// char* async_call(char* method_name, uint64_t instance_id, char* params)
typedef _async_call = Pointer<Utf8> Function(Pointer<Utf8>, Int64, Pointer<Utf8>);
typedef _AsyncCall = Pointer<Utf8> Function(Pointer<Utf8>, int, Pointer<Utf8>);

// // char* try_pull_result(uint64_t job_id)
// // char *get_wallet_info(uint64_t hwallet)
// // char* get_wallet_status(uint64_t hwallet)
typedef _stringFunctionWithInt64 = Pointer<Utf8> Function(Int64);
typedef _StringFunctionWithIntHWallet = Pointer<Utf8> Function(int);

// bool setup_node(char *address, char *login, char *password, bool use_ssl, bool is_light_wallet, char *error)
typedef _setup_node = Int8 Function(Pointer<Utf8>, Pointer<Utf8>?, Pointer<Utf8>?, Int8, Int8, Pointer<Utf8>);
typedef _SetupNode = int Function(Pointer<Utf8>, Pointer<Utf8>?, Pointer<Utf8>?, int, int, Pointer<Utf8>);

// char* set_password(uint64_t hwallet, char *password, Utf8Box &error)
typedef _set_password = Pointer<Utf8> Function(Int64 hWallet, Pointer<Utf8> password, Pointer<Utf8Box> error);
typedef _SetPassword = Pointer<Utf8> Function(int hWallet, Pointer<Utf8> password, Pointer<Utf8Box> error);

// char*  get_connectivity_status()
// char* get_version()
typedef _stringFunction = Pointer<Utf8> Function();

class ApiCalls {
  static String _convertUTF8ToString({required Pointer<Utf8> pointer}) {
    final str = pointer.toDartString();
    //final str = pointer.toDartStringAllowingMalformed();
    calloc.free(pointer);
    return str;
  }

  static String _performApiCall(
    Pointer<Utf8> Function() apiCall, {
    List<Pointer<Utf8>>? pointersToFree,
  }) {
    try {
      return _convertUTF8ToString(pointer: apiCall());
    } finally {
      if (pointersToFree != null) {
        for (var pointer in pointersToFree) {
          calloc.free(pointer);
        }
      }
    }
  }

  static final _createWalletNative = zanoApi.lookup<NativeFunction<_create_wallet>>('create_wallet').asFunction<_CreateWallet>();

  static String createWallet({
    required String path,
    required String password,
    String language = '',
    int nettype = 0,
  }) {
    final pathPointer = path.toNativeUtf8();
    final passwordPointer = password.toNativeUtf8();
    final languagePointer = language.toNativeUtf8();
    final errorMessagePointer = ''.toNativeUtf8();
    final result = _performApiCall(
        () => _createWalletNative(
              pathPointer,
              passwordPointer,
              languagePointer,
              nettype,
              errorMessagePointer,
            ),
        pointersToFree: [pathPointer, passwordPointer, languagePointer, errorMessagePointer]);

    return result;
  }

  static final _restoreWalletFromSeedNative = zanoApi.lookup<NativeFunction<_restore_wallet_from_seed>>('restore_wallet_from_seed').asFunction<_RestoreWalletFromSeed>();

  static String restoreWalletFromSeed({
    required String path,
    required String password,
    required String seed,
  }) {
    final pathPointer = path.toNativeUtf8();
    final passwordPointer = password.toNativeUtf8();
    final seedPointer = seed.toNativeUtf8();
    final errorMessagePointer = ''.toNativeUtf8();
    final result = _performApiCall(
      () => _restoreWalletFromSeedNative(
        pathPointer,
        passwordPointer,
        seedPointer,
        0,
        0,
        errorMessagePointer,
      ),
      pointersToFree: [
        pathPointer,
        passwordPointer,
        seedPointer,
        errorMessagePointer,
      ],
    );
    return result;
  }

  static final _loadWalletNative = zanoApi.lookup<NativeFunction<_load_wallet>>('load_wallet').asFunction<_LoadWallet>();

  static String loadWallet({
    required String path,
    required String password,
    int nettype = 0,
  }) {
    final pathPointer = path.toNativeUtf8();
    final passwordPointer = password.toNativeUtf8();
    final result = _performApiCall(
      () => _loadWalletNative(
        pathPointer,
        passwordPointer,
        nettype,
      ),
      pointersToFree: [
        pathPointer,
        passwordPointer,
      ],
    );
    return result;
  }

  static final _isWalletExistNative = zanoApi.lookup<NativeFunction<_is_wallet_exist>>('is_wallet_exist').asFunction<_IsWalletExist>();

  static bool isWalletExist({required String path}) {
    final pathPointer = path.toNativeUtf8();
    final isExist = _isWalletExistNative(pathPointer) != 0;
    calloc.free(pathPointer);
    return isExist;
  }

  static final _closeWalletNative = zanoApi.lookup<NativeFunction<_close_wallet>>('close_wallet').asFunction<_closeWallet>();

  static String closeWallet({required int hWallet}) => _performApiCall(() => _closeWalletNative(hWallet));

  static final _getWalletInfoNative = zanoApi.lookup<NativeFunction<_stringFunctionWithInt64>>('get_wallet_info').asFunction<_StringFunctionWithIntHWallet>();

  static String getWalletInfo(int hWallet) => _performApiCall(() => _getWalletInfoNative(hWallet));

  static final _getWalletStatusNative = zanoApi.lookup<NativeFunction<_stringFunctionWithInt64>>('get_wallet_status').asFunction<_StringFunctionWithIntHWallet>();

  static String getWalletStatus({required int hWallet}) => _performApiCall(() => _getWalletStatusNative(hWallet));

  static final _getCurrentTxFeeNative = zanoApi.lookup<NativeFunction<_get_current_tx_fee>>('get_current_tx_fee').asFunction<_getCurrentTxFee>();

  static int getCurrentTxFee({required int priority}) => _getCurrentTxFeeNative(priority);

  static final _getConnectivityStatusNative = zanoApi.lookup<NativeFunction<_stringFunction>>('get_connectivity_status').asFunction<_stringFunction>();

  static String getConnectivityStatus() => _performApiCall(() => _getConnectivityStatusNative());

  static final _getAddressInfoNative = zanoApi.lookup<NativeFunction<_GetAddressInfo>>('get_address_info').asFunction<_GetAddressInfo>();

  static String getAddressInfo({required String address}) {
    final addressPointer = address.toNativeUtf8();
    final result = _performApiCall(
      () => _getAddressInfoNative(addressPointer),
      pointersToFree: [addressPointer],
    );
    return result;
  }

  static final _asyncCallNative = zanoApi.lookup<NativeFunction<_async_call>>('async_call').asFunction<_AsyncCall>();
  static final _syncCallNative = zanoApi.lookup<NativeFunction<_async_call>>('sync_call').asFunction<_AsyncCall>();

  static String syncCall({required String methodName, required int hWallet, required String params}) {
    final methodNamePointer = methodName.toNativeUtf8();
    final paramsPointer = params.toNativeUtf8();
    final result = _performApiCall(
      () => _syncCallNative(
        methodNamePointer,
        hWallet,
        paramsPointer,
      ),
      pointersToFree: [
        methodNamePointer,
        paramsPointer,
      ],
    );
    return result;
  }

  static String asyncCall({required String methodName, required int hWallet, required String params}) {
    final methodNamePointer = methodName.toNativeUtf8();
    final paramsPointer = params.toNativeUtf8();
    final result = _performApiCall(
      () => _asyncCallNative(
        methodNamePointer,
        hWallet,
        paramsPointer,
      ),
      pointersToFree: [
        methodNamePointer,
        paramsPointer,
      ],
    );
    return result;
  }

  static final _tryPullResultNative = zanoApi.lookup<NativeFunction<_stringFunctionWithInt64>>('try_pull_result').asFunction<_StringFunctionWithIntHWallet>();

  static String tryPullResult(int jobId) {
    final result = _performApiCall(() => _tryPullResultNative(jobId));
    return result;
  }

  static final _setupNodeNative = zanoApi.lookup<NativeFunction<_setup_node>>('setup_node').asFunction<_SetupNode>();

  static bool setupNode({
    required String address,
    required String login,
    required String password,
    bool useSSL = false,
    bool isLightWallet = false,
  }) {
    final addressPointer = address.toNativeUtf8();
    final loginPointer = login.toNativeUtf8();
    final passwordPointer = password.toNativeUtf8();
    final errorMessagePointer = ''.toNativeUtf8();
    final isSetupNode = _setupNodeNative(
          addressPointer,
          loginPointer,
          passwordPointer,
          _boolToInt(useSSL),
          _boolToInt(isLightWallet),
          errorMessagePointer,
        ) !=
        0;

    calloc.free(addressPointer);
    calloc.free(loginPointer);
    calloc.free(passwordPointer);
    return isSetupNode;
  }

  static final _setPasswordNative = zanoApi.lookup<NativeFunction<_set_password>>('set_password').asFunction<_SetPassword>();

  static String setPassword({required int hWallet, required String password}) {
    final passwordPointer = password.toNativeUtf8();
    final errorMessagePointer = calloc<Utf8Box>();
    final result = _performApiCall(
      () => _setPasswordNative(
        hWallet,
        passwordPointer,
        errorMessagePointer,
      ),
      pointersToFree: [passwordPointer],
    );
    calloc.free(errorMessagePointer);
    return result;
  }

  static final _getVersionNative = zanoApi.lookup<NativeFunction<_stringFunction>>('get_version').asFunction<_stringFunction>();

  static String getVersion() {
    final result = _performApiCall(() => _getVersionNative());
    return result;
  }

  static int _boolToInt(bool value) => value ? 1 : 0;
}
