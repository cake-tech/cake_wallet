/// Dart FFI bindings to the native Rust PIVX Sapling library.
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

/// FFI buffer structure matching Rust's FFIBuffer.
class FFIBuffer extends Struct {
  external Pointer<Uint8> data;

  @Size()
  external int len;
}

DynamicLibrary _loadLibrary() {
  final overridePath = Platform.environment['PIVX_SAPLING_LIBRARY_PATH'];
  if (overridePath != null && overridePath.isNotEmpty) {
    return DynamicLibrary.open(overridePath);
  }

  if (Platform.isAndroid) {
    return DynamicLibrary.open('libcw_pivx_sapling.so');
  } else if (Platform.isIOS) {
    // iOS: Rust static lib is force-loaded into cw_pivx.framework
    try {
      final lib = DynamicLibrary.open('cw_pivx.framework/cw_pivx');
      lib.lookup('cw_pivx_version');
      return lib;
    } catch (e) {
      // symbols may instead be linked into the main binary
      return DynamicLibrary.process();
    }
  } else if (Platform.isMacOS) {
    return _openFirstAvailableLibraryPath(const [
      'libcw_pivx_sapling.dylib',
      'cw_pivx/macos/Frameworks/libcw_pivx_sapling.dylib',
      '../cw_pivx/macos/Frameworks/libcw_pivx_sapling.dylib',
      'macos/Frameworks/libcw_pivx_sapling.dylib',
    ]);
  } else if (Platform.isLinux) {
    return DynamicLibrary.open('libcw_pivx_sapling.so');
  } else if (Platform.isWindows) {
    return DynamicLibrary.open('cw_pivx_sapling.dll');
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}

DynamicLibrary _openFirstAvailableLibraryPath(List<String> paths) {
  Object? lastError;
  for (final path in paths) {
    try {
      return DynamicLibrary.open(path);
    } catch (error) {
      lastError = error;
    }
  }

  throw StateError(
    'Unable to load native PIVX Sapling library from ${paths.join(', ')}'
    '${lastError == null ? '' : ': $lastError'}',
  );
}

late final DynamicLibrary _nativeLib;
bool _nativeLibLoaded = false;
String? _nativeLibError;

void _ensureLoaded() {
  if (_nativeLibLoaded) return;
  try {
    _nativeLib = _loadLibrary();
    _nativeLibLoaded = true;
  } catch (e) {
    _nativeLibError = e.toString();
  }
}

String _nativeUnavailableMessage() =>
    'Native library not available: ${_nativeLibError ?? 'unknown load error'}';

/// Best-effort hygiene for short-lived FFI copies of key material; no guarantee
/// about allocator copies, paging or Rust-owned data.
void zeroNativeUint8Buffer(Pointer<Uint8> pointer, int length) {
  if (pointer == nullptr || length <= 0) return;

  pointer.asTypedList(length).fillRange(0, length, 0);
}

/// [value] recovers the `toNativeUtf8()` allocation length, including the NUL.
void zeroNativeUtf8String(Pointer<Utf8> pointer, String? value) {
  if (pointer == nullptr || value == null) return;

  zeroNativeUint8Buffer(pointer.cast<Uint8>(), utf8.encode(value).length + 1);
}

typedef _FreeStringC = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

typedef _FreeBufferC = Void Function(FFIBuffer);
typedef _FreeBufferDart = void Function(FFIBuffer);

typedef _GetLastErrorC = Pointer<Utf8> Function();
typedef _GetLastErrorDart = Pointer<Utf8> Function();

// Trailing isTestnet args stay in the C ABI; Dart always passes 0 (mainnet).
typedef _InitKeysC = Int64 Function(
    Pointer<Uint8> seed, Size seedLen, Uint8 isTestnet);
typedef _InitKeysDart = int Function(
    Pointer<Uint8> seed, int seedLen, int isTestnet);

typedef _DisposeKeysC = Void Function(Int64 handle);
typedef _DisposeKeysDart = void Function(int handle);

typedef _GetDefaultAddressC = Pointer<Utf8> Function(Int64 handle);
typedef _GetDefaultAddressDart = Pointer<Utf8> Function(int handle);

typedef _DeriveAddressC = Pointer<Utf8> Function(Int64 handle, Uint64 index);
typedef _DeriveAddressDart = Pointer<Utf8> Function(int handle, int index);

typedef _ValidateAddressC = Uint8 Function(
    Pointer<Utf8> address, Uint8 isTestnet);
typedef _ValidateAddressDart = int Function(
    Pointer<Utf8> address, int isTestnet);

typedef _InitSyncEngineC = Int64 Function(Uint8 isTestnet);
typedef _InitSyncEngineDart = int Function(int isTestnet);

typedef _DisposeSyncEngineC = Void Function(Int64 handle);
typedef _DisposeSyncEngineDart = void Function(int handle);

typedef _ResetSyncC = Void Function(Int64 handle);
typedef _ResetSyncDart = void Function(int handle);

// Trial decryption for detecting incoming shielded transactions
typedef _TryDecryptOutputC = Uint64 Function(
  Int64 keyHandle,
  Int64 syncHandle,
  Pointer<Uint8> cmu,
  Pointer<Uint8> epk,
  Pointer<Uint8> encCiphertext,
  Uint32 height,
  Uint32 txIndex,
  Uint32 outputIndex,
  Uint64 position,
);
typedef _TryDecryptOutputDart = int Function(
  int keyHandle,
  int syncHandle,
  Pointer<Uint8> cmu,
  Pointer<Uint8> epk,
  Pointer<Uint8> encCiphertext,
  int height,
  int txIndex,
  int outputIndex,
  int position,
);

// Check nullifier (mark notes as spent)
typedef _CheckNullifierC = Uint8 Function(
    Int64 syncHandle, Pointer<Uint8> nullifier);
typedef _CheckNullifierDart = int Function(
    int syncHandle, Pointer<Uint8> nullifier);

typedef _InitProverC = Int32 Function(Pointer<Utf8> paramsDir);
typedef _InitProverDart = int Function(Pointer<Utf8> paramsDir);

typedef _DisposeProverC = Void Function();
typedef _DisposeProverDart = void Function();

// Advanced transaction building with explicit notes/witnesses
typedef _BuildShieldedTxC = FFIBuffer Function(
  Int64 keyHandle,
  Pointer<Utf8> notesJson,
  Pointer<Utf8> toAddress,
  Uint64 amount,
  Pointer<Utf8> memo,
  Uint64 fee,
  Pointer<Utf8> anchorHex,
);
typedef _BuildShieldedTxDart = FFIBuffer Function(
  int keyHandle,
  Pointer<Utf8> notesJson,
  Pointer<Utf8> toAddress,
  int amount,
  Pointer<Utf8> memo,
  int fee,
  Pointer<Utf8> anchorHex,
);

typedef _BuildShieldTxC = FFIBuffer Function(
  Int64 keyHandle,
  Pointer<Utf8> utxosJson,
  Pointer<Utf8> toAddress,
  Uint64 amount,
  Pointer<Utf8> memo,
  Uint64 fee,
  Pointer<Utf8> changeAddress,
  Uint64 change,
);
typedef _BuildShieldTxDart = FFIBuffer Function(
  int keyHandle,
  Pointer<Utf8> utxosJson,
  Pointer<Utf8> toAddress,
  int amount,
  Pointer<Utf8> memo,
  int fee,
  Pointer<Utf8> changeAddress,
  int change,
);

late final _freeString = _nativeLib
    .lookupFunction<_FreeStringC, _FreeStringDart>('cw_pivx_free_string');

late final _freeBuffer = _nativeLib
    .lookupFunction<_FreeBufferC, _FreeBufferDart>('cw_pivx_free_buffer');

late final _getLastError =
    _nativeLib.lookupFunction<_GetLastErrorC, _GetLastErrorDart>(
        'cw_pivx_get_last_error');

late final _initKeys =
    _nativeLib.lookupFunction<_InitKeysC, _InitKeysDart>('cw_pivx_init_keys');

late final _disposeKeys = _nativeLib
    .lookupFunction<_DisposeKeysC, _DisposeKeysDart>('cw_pivx_dispose_keys');

late final _getDefaultAddress =
    _nativeLib.lookupFunction<_GetDefaultAddressC, _GetDefaultAddressDart>(
        'cw_pivx_get_default_address');

late final _deriveAddress =
    _nativeLib.lookupFunction<_DeriveAddressC, _DeriveAddressDart>(
        'cw_pivx_derive_address');

late final _validateAddress =
    _nativeLib.lookupFunction<_ValidateAddressC, _ValidateAddressDart>(
        'cw_pivx_validate_address');

late final _initSyncEngine =
    _nativeLib.lookupFunction<_InitSyncEngineC, _InitSyncEngineDart>(
        'cw_pivx_init_sync_engine');

late final _disposeSyncEngine =
    _nativeLib.lookupFunction<_DisposeSyncEngineC, _DisposeSyncEngineDart>(
        'cw_pivx_dispose_sync_engine');

late final _resetSync = _nativeLib
    .lookupFunction<_ResetSyncC, _ResetSyncDart>('cw_pivx_reset_sync');

late final _tryDecryptOutput =
    _nativeLib.lookupFunction<_TryDecryptOutputC, _TryDecryptOutputDart>(
        'cw_pivx_try_decrypt_output');

late final _checkNullifier =
    _nativeLib.lookupFunction<_CheckNullifierC, _CheckNullifierDart>(
        'cw_pivx_check_nullifier');

late final _initProver = _nativeLib
    .lookupFunction<_InitProverC, _InitProverDart>('cw_pivx_init_prover');

late final _disposeProver =
    _nativeLib.lookupFunction<_DisposeProverC, _DisposeProverDart>(
        'cw_pivx_dispose_prover');

late final _buildShieldedTx =
    _nativeLib.lookupFunction<_BuildShieldedTxC, _BuildShieldedTxDart>(
        'cw_pivx_build_shielded_tx');
late final _buildShieldTx =
    _nativeLib.lookupFunction<_BuildShieldTxC, _BuildShieldTxDart>(
        'cw_pivx_build_shield_tx');

// Local witness-root verification
typedef _VerifyWitnessRootC = Int32 Function(
  Pointer<Utf8> witnessHex,
  Pointer<Utf8> cmuHex,
  Pointer<Utf8> anchorHex,
  Uint64 position,
);
typedef _VerifyWitnessRootDart = int Function(
  Pointer<Utf8> witnessHex,
  Pointer<Utf8> cmuHex,
  Pointer<Utf8> anchorHex,
  int position,
);

late final _verifyWitnessRoot =
    _nativeLib.lookupFunction<_VerifyWitnessRootC, _VerifyWitnessRootDart>(
        'pivx_sapling_verify_witness_root');

typedef _GetSpendableNotesC = Pointer<Utf8> Function(Int64 syncHandle);
typedef _GetSpendableNotesDart = Pointer<Utf8> Function(int syncHandle);

late final _getSpendableNotes =
    _nativeLib.lookupFunction<_GetSpendableNotesC, _GetSpendableNotesDart>(
        'cw_pivx_get_spendable_notes');

typedef _GetNoteAtPositionC = Pointer<Utf8> Function(
    Int64 syncHandle, Uint64 position);
typedef _GetNoteAtPositionDart = Pointer<Utf8> Function(
    int syncHandle, int position);
late final _getNoteAtPosition =
    _nativeLib.lookupFunction<_GetNoteAtPositionC, _GetNoteAtPositionDart>(
        'cw_pivx_get_note_at_position');

typedef _RestoreNoteC = Int32 Function(
    Int64 keyHandle, Int64 syncHandle, Pointer<Utf8> noteJson);
typedef _RestoreNoteDart = int Function(
    int keyHandle, int syncHandle, Pointer<Utf8> noteJson);

late final _restoreNote = _nativeLib
    .lookupFunction<_RestoreNoteC, _RestoreNoteDart>('cw_pivx_restore_note');

String? getLastError() {
  _ensureLoaded();
  if (!_nativeLibLoaded) return _nativeLibError;

  final ptr = _getLastError();
  if (ptr == nullptr) return null;

  final error = ptr.toDartString();
  _freeString(ptr);
  return error;
}

bool validateAddress(String address) {
  _ensureLoaded();
  if (!_nativeLibLoaded) return false;

  final addressPtr = address.toNativeUtf8();
  try {
    return _validateAddress(addressPtr, 0) == 1;
  } finally {
    zeroNativeUtf8String(addressPtr, address);
    malloc.free(addressPtr);
  }
}

/// Recompute the Merkle root from [witnessHex] (32 sibling hashes, 2048 hex
/// chars) and compare to [anchorHex]. false on a clean mismatch; throws
/// [StateError] when verification itself cannot run.
bool verifyWitnessRoot({
  required String witnessHex,
  required String cmuHex,
  required String anchorHex,
  required int position,
}) {
  _ensureLoaded();
  if (!_nativeLibLoaded) throw StateError(_nativeUnavailableMessage());

  final witnessPtr = witnessHex.toNativeUtf8();
  final cmuPtr = cmuHex.toNativeUtf8();
  final anchorPtr = anchorHex.toNativeUtf8();
  try {
    final result = _verifyWitnessRoot(witnessPtr, cmuPtr, anchorPtr, position);
    if (result == 1) return true;
    if (result == 0) return false;
    throw StateError(
        'Witness root verification error: ${getLastError() ?? 'unknown'}');
  } finally {
    zeroNativeUtf8String(witnessPtr, witnessHex);
    malloc.free(witnessPtr);
    zeroNativeUtf8String(cmuPtr, cmuHex);
    malloc.free(cmuPtr);
    zeroNativeUtf8String(anchorPtr, anchorHex);
    malloc.free(anchorPtr);
  }
}

/// Loads ~50MB of Groth16 params. false on failure; see [getLastError].
bool initProver(String paramsDir) {
  _ensureLoaded();
  if (!_nativeLibLoaded) return false;

  final dirPtr = paramsDir.toNativeUtf8();
  try {
    return _initProver(dirPtr) == 0;
  } finally {
    zeroNativeUtf8String(dirPtr, paramsDir);
    malloc.free(dirPtr);
  }
}

void disposeProver() {
  _ensureLoaded();
  if (!_nativeLibLoaded) return;
  _disposeProver();
}

List<Map<String, dynamic>> getSpendableNotes(int syncHandle) {
  _ensureLoaded();
  if (!_nativeLibLoaded) return [];

  final ptr = _getSpendableNotes(syncHandle);
  if (ptr == nullptr) {
    return [];
  }

  try {
    final jsonStr = ptr.toDartString();
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } finally {
    _freeString(ptr);
  }
}

/// One note by position; avoids serializing every note on each decrypt match.
Map<String, dynamic>? getNoteAtPosition(int syncHandle, int position) {
  _ensureLoaded();
  if (!_nativeLibLoaded) return null;

  final ptr = _getNoteAtPosition(syncHandle, position);
  if (ptr == nullptr) return null;

  try {
    return Map<String, dynamic>.from(jsonDecode(ptr.toDartString()) as Map);
  } finally {
    _freeString(ptr);
  }
}

bool restoreNote({
  required int keyHandle,
  required int syncHandle,
  required Map<String, dynamic> noteData,
}) {
  _ensureLoaded();
  if (!_nativeLibLoaded) return false;

  final jsonStr = jsonEncode(noteData);
  final jsonPtr = jsonStr.toNativeUtf8();

  try {
    return _restoreNote(keyHandle, syncHandle, jsonPtr) == 1;
  } finally {
    zeroNativeUtf8String(jsonPtr, jsonStr);
    malloc.free(jsonPtr);
  }
}

/// [anchorHex] must be serialization order.
Map<String, dynamic> buildShieldedTransaction({
  required int keyHandle,
  required String notesJson,
  required String toAddress,
  required int amount,
  String? memo,
  required int fee,
  required String anchorHex,
}) {
  _ensureLoaded();
  if (!_nativeLibLoaded) {
    throw Exception('Native library not available: $_nativeLibError');
  }

  final notesPtr = notesJson.toNativeUtf8();
  final toPtr = toAddress.toNativeUtf8();
  final memoPtr = memo?.toNativeUtf8() ?? nullptr;
  final anchorPtr = anchorHex.toNativeUtf8();

  try {
    final buffer = _buildShieldedTx(
      keyHandle,
      notesPtr,
      toPtr,
      amount,
      memoPtr,
      fee,
      anchorPtr,
    );

    if (buffer.data == nullptr || buffer.len == 0) {
      throw Exception(getLastError() ?? 'Failed to build transaction');
    }

    final resultStr = buffer.data.cast<Utf8>().toDartString(length: buffer.len);
    _freeBuffer(buffer);

    return Map<String, dynamic>.from(
      (const JsonDecoder().convert(resultStr)) as Map,
    );
  } finally {
    zeroNativeUtf8String(notesPtr, notesJson);
    malloc.free(notesPtr);
    zeroNativeUtf8String(toPtr, toAddress);
    malloc.free(toPtr);
    if (memoPtr != nullptr) {
      zeroNativeUtf8String(memoPtr, memo);
      malloc.free(memoPtr);
    }
    zeroNativeUtf8String(anchorPtr, anchorHex);
    malloc.free(anchorPtr);
  }
}

/// t-to-z. Must balance exactly: sum(utxos) = amount + change + fee.
Map<String, dynamic> buildShieldTransaction({
  required int keyHandle,
  required String utxosJson,
  required String toAddress,
  required int amount,
  String? memo,
  required int fee,
  String? changeAddress,
  int change = 0,
}) {
  _ensureLoaded();
  if (!_nativeLibLoaded) {
    throw Exception('Native library not available: $_nativeLibError');
  }

  final utxosPtr = utxosJson.toNativeUtf8();
  final toPtr = toAddress.toNativeUtf8();
  final memoPtr = memo?.toNativeUtf8() ?? nullptr;
  final changePtr = changeAddress?.toNativeUtf8() ?? nullptr;

  try {
    final buffer = _buildShieldTx(
      keyHandle,
      utxosPtr,
      toPtr,
      amount,
      memoPtr,
      fee,
      changePtr,
      change,
    );

    if (buffer.data == nullptr || buffer.len == 0) {
      throw Exception(getLastError() ?? 'Failed to build shield transaction');
    }

    final resultStr = buffer.data.cast<Utf8>().toDartString(length: buffer.len);
    _freeBuffer(buffer);

    return Map<String, dynamic>.from(
      (const JsonDecoder().convert(resultStr)) as Map,
    );
  } finally {
    zeroNativeUtf8String(utxosPtr, utxosJson);
    malloc.free(utxosPtr);
    zeroNativeUtf8String(toPtr, toAddress);
    malloc.free(toPtr);
    if (memoPtr != nullptr) {
      zeroNativeUtf8String(memoPtr, memo);
      malloc.free(memoPtr);
    }
    if (changePtr != nullptr) {
      zeroNativeUtf8String(changePtr, changeAddress);
      malloc.free(changePtr);
    }
  }
}

String _takeString(Pointer<Utf8> ptr, String fallbackError) {
  if (ptr == nullptr) throw Exception(getLastError() ?? fallbackError);
  try {
    return ptr.toDartString();
  } finally {
    _freeString(ptr);
  }
}

class SaplingKeys {
  final int _handle;
  bool _disposed = false;

  SaplingKeys._(this._handle);

  static SaplingKeys fromSeed(Uint8List seed) {
    _ensureLoaded();
    if (!_nativeLibLoaded) {
      throw Exception('Native library not available: $_nativeLibError');
    }

    final seedPtr = malloc<Uint8>(seed.length);
    try {
      seedPtr.asTypedList(seed.length).setAll(0, seed);

      final handle = _initKeys(seedPtr, seed.length, 0);
      if (handle < 0) {
        throw Exception(getLastError() ?? 'Failed to initialize keys');
      }

      return SaplingKeys._(handle);
    } finally {
      zeroNativeUint8Buffer(seedPtr, seed.length);
      malloc.free(seedPtr);
    }
  }

  String getDefaultAddress() {
    _checkDisposed();
    return _takeString(_getDefaultAddress(_handle), 'Failed to get address');
  }

  String deriveAddress(int index) {
    _checkDisposed();
    return _takeString(
        _deriveAddress(_handle, index), 'Failed to derive address');
  }

  void dispose() {
    if (!_disposed) {
      _disposeKeys(_handle);
      _disposed = true;
    }
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('SaplingKeys has been disposed');
    }
  }

  int get handle {
    _checkDisposed();
    return _handle;
  }
}

class SaplingSyncEngine {
  final int _handle;
  bool _disposed = false;

  SaplingSyncEngine._(this._handle);

  int get handle => _handle;

  factory SaplingSyncEngine() {
    _ensureLoaded();
    if (!_nativeLibLoaded) {
      throw Exception(_nativeUnavailableMessage());
    }
    final handle = _initSyncEngine(0);
    if (handle < 0) {
      throw Exception(getLastError() ?? 'Failed to initialize sync engine');
    }
    return SaplingSyncEngine._(handle);
  }

  void reset() {
    _checkDisposed();
    _resetSync(_handle);
  }

  /// Note value on a trial-decrypt hit, 0 otherwise.
  int tryDecryptOutput({
    required SaplingKeys keys,
    required Uint8List cmu,
    required Uint8List epk,
    required Uint8List encCiphertext,
    required int height,
    required int txIndex,
    required int outputIndex,
    required int position,
  }) {
    _checkDisposed();

    if (cmu.length != 32) throw ArgumentError('cmu must be 32 bytes');
    if (epk.length != 32) throw ArgumentError('epk must be 32 bytes');
    if (encCiphertext.length != 580)
      throw ArgumentError('encCiphertext must be 580 bytes');

    final cmuPtr = malloc<Uint8>(32);
    final epkPtr = malloc<Uint8>(32);
    final encPtr = malloc<Uint8>(580);

    try {
      cmuPtr.asTypedList(32).setAll(0, cmu);
      epkPtr.asTypedList(32).setAll(0, epk);
      encPtr.asTypedList(580).setAll(0, encCiphertext);

      final result = _tryDecryptOutput(
        keys.handle,
        _handle,
        cmuPtr,
        epkPtr,
        encPtr,
        height,
        txIndex,
        outputIndex,
        position,
      );

      return result;
    } finally {
      zeroNativeUint8Buffer(cmuPtr, 32);
      zeroNativeUint8Buffer(epkPtr, 32);
      zeroNativeUint8Buffer(encPtr, 580);
      malloc.free(cmuPtr);
      malloc.free(epkPtr);
      malloc.free(encPtr);
    }
  }

  /// Mark the wallet note matching [nullifier] as spent; true if one was marked.
  bool checkNullifier(Uint8List nullifier) {
    _checkDisposed();

    if (nullifier.length != 32)
      throw ArgumentError('nullifier must be 32 bytes');

    final nullifierPtr = malloc<Uint8>(32);
    try {
      nullifierPtr.asTypedList(32).setAll(0, nullifier);
      return _checkNullifier(_handle, nullifierPtr) == 1;
    } finally {
      zeroNativeUint8Buffer(nullifierPtr, 32);
      malloc.free(nullifierPtr);
    }
  }

  void dispose() {
    if (!_disposed) {
      _disposeSyncEngine(_handle);
      _disposed = true;
    }
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('SaplingSyncEngine has been disposed');
    }
  }
}
