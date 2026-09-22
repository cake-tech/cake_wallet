/// Dart FFI bindings to the native Rust PIVX Sapling library.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:cw_pivx/src/sapling/sapling_constants.dart';

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
String? _nativeSelfTestError;

bool get isSaplingFFIAvailable {
  _ensureLoaded();
  return _nativeLibLoaded;
}

String? get saplingFFIError => _nativeLibError;

String? get saplingFFISelfTestError => _nativeSelfTestError;

class SaplingNativeSelfTestResult {
  const SaplingNativeSelfTestResult({
    required this.loaded,
    required this.symbolsReady,
    required this.feeMatchesPolicy,
    this.version,
    this.error,
  });

  final bool loaded;
  final bool symbolsReady;
  final bool feeMatchesPolicy;
  final String? version;
  final String? error;

  bool get passed =>
      loaded && symbolsReady && feeMatchesPolicy && error == null;
}

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

/// Overwrite a native byte buffer before freeing it. Best-effort memory hygiene
/// for short-lived FFI copies of key material (e.g. BIP39 seed bytes); makes no
/// guarantee about allocator copies, paging, crash dumps, or Rust-owned data.
void zeroNativeUint8Buffer(Pointer<Uint8> pointer, int length) {
  if (pointer == nullptr || length <= 0) return;

  pointer.asTypedList(length).fillRange(0, length, 0);
}

/// Overwrite a native UTF-8 string before freeing it. [value] recovers the
/// `toNativeUtf8()` allocation length, including the trailing NUL.
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

typedef _VersionC = Pointer<Utf8> Function();
typedef _VersionDart = Pointer<Utf8> Function();

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

typedef _GetViewingKeyC = Pointer<Utf8> Function(Int64 handle);
typedef _GetViewingKeyDart = Pointer<Utf8> Function(int handle);

typedef _ValidateAddressC = Uint8 Function(
    Pointer<Utf8> address, Uint8 isTestnet);
typedef _ValidateAddressDart = int Function(
    Pointer<Utf8> address, int isTestnet);

typedef _InitSyncEngineC = Int64 Function(Uint8 isTestnet);
typedef _InitSyncEngineDart = int Function(int isTestnet);

typedef _DisposeSyncEngineC = Void Function(Int64 handle);
typedef _DisposeSyncEngineDart = void Function(int handle);

typedef _GetSyncHeightC = Uint32 Function(Int64 handle);
typedef _GetSyncHeightDart = int Function(int handle);

typedef _GetShieldedBalanceC = Uint64 Function(Int64 handle);
typedef _GetShieldedBalanceDart = int Function(int handle);

typedef _GetUnspentNoteCountC = Size Function(Int64 handle);
typedef _GetUnspentNoteCountDart = int Function(int handle);

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

typedef _SetSyncHeightC = Void Function(Int64 syncHandle, Uint32 height);
typedef _SetSyncHeightDart = void Function(int syncHandle, int height);

typedef _EstimateFeeC = Uint64 Function(
    Size spends, Size outputs, Size tInputs, Size tOutputs);
typedef _EstimateFeeDart = int Function(
    int spends, int outputs, int tInputs, int tOutputs);

typedef _InitProverC = Int32 Function(Pointer<Utf8> paramsDir);
typedef _InitProverDart = int Function(Pointer<Utf8> paramsDir);

typedef _IsProverInitializedC = Uint8 Function();
typedef _IsProverInitializedDart = int Function();

typedef _DisposeProverC = Void Function();
typedef _DisposeProverDart = void Function();

typedef _HasProvingParamsC = Uint8 Function(Pointer<Utf8> path);
typedef _HasProvingParamsDart = int Function(Pointer<Utf8> path);

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

late final _version =
    _nativeLib.lookupFunction<_VersionC, _VersionDart>('cw_pivx_version');

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

late final _getViewingKey =
    _nativeLib.lookupFunction<_GetViewingKeyC, _GetViewingKeyDart>(
        'cw_pivx_get_viewing_key');

late final _validateAddress =
    _nativeLib.lookupFunction<_ValidateAddressC, _ValidateAddressDart>(
        'cw_pivx_validate_address');

late final _initSyncEngine =
    _nativeLib.lookupFunction<_InitSyncEngineC, _InitSyncEngineDart>(
        'cw_pivx_init_sync_engine');

late final _disposeSyncEngine =
    _nativeLib.lookupFunction<_DisposeSyncEngineC, _DisposeSyncEngineDart>(
        'cw_pivx_dispose_sync_engine');

late final _getSyncHeight =
    _nativeLib.lookupFunction<_GetSyncHeightC, _GetSyncHeightDart>(
        'cw_pivx_get_sync_height');

late final _getShieldedBalance =
    _nativeLib.lookupFunction<_GetShieldedBalanceC, _GetShieldedBalanceDart>(
        'cw_pivx_get_shielded_balance');

late final _getUnspentNoteCount =
    _nativeLib.lookupFunction<_GetUnspentNoteCountC, _GetUnspentNoteCountDart>(
        'cw_pivx_get_unspent_note_count');

late final _resetSync = _nativeLib
    .lookupFunction<_ResetSyncC, _ResetSyncDart>('cw_pivx_reset_sync');

late final _tryDecryptOutput =
    _nativeLib.lookupFunction<_TryDecryptOutputC, _TryDecryptOutputDart>(
        'cw_pivx_try_decrypt_output');

late final _checkNullifier =
    _nativeLib.lookupFunction<_CheckNullifierC, _CheckNullifierDart>(
        'cw_pivx_check_nullifier');

late final _setSyncHeight =
    _nativeLib.lookupFunction<_SetSyncHeightC, _SetSyncHeightDart>(
        'cw_pivx_set_sync_height');

late final _estimateFee = _nativeLib
    .lookupFunction<_EstimateFeeC, _EstimateFeeDart>('cw_pivx_estimate_fee');

late final _initProver = _nativeLib
    .lookupFunction<_InitProverC, _InitProverDart>('cw_pivx_init_prover');

late final _isProverInitialized =
    _nativeLib.lookupFunction<_IsProverInitializedC, _IsProverInitializedDart>(
        'cw_pivx_is_prover_initialized');

late final _disposeProver =
    _nativeLib.lookupFunction<_DisposeProverC, _DisposeProverDart>(
        'cw_pivx_dispose_prover');

late final _buildShieldedTx =
    _nativeLib.lookupFunction<_BuildShieldedTxC, _BuildShieldedTxDart>(
        'cw_pivx_build_shielded_tx');
late final _buildShieldTx =
    _nativeLib.lookupFunction<_BuildShieldTxC, _BuildShieldTxDart>(
        'cw_pivx_build_shield_tx');

late final _hasProvingParams =
    _nativeLib.lookupFunction<_HasProvingParamsC, _HasProvingParamsDart>(
        'cw_pivx_has_proving_params');

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

String getVersion() {
  _ensureLoaded();
  if (!_nativeLibLoaded) return 'not loaded';

  final ptr = _version();
  if (ptr == nullptr) return 'unknown';

  final version = ptr.toDartString();
  _freeString(ptr);
  return version;
}

/// Native-library self-test for release validation: library loads, FFI symbols
/// resolve, version is callable, and native fee estimation matches the fee policy.
SaplingNativeSelfTestResult runSaplingNativeSelfTest() {
  _ensureLoaded();
  if (!_nativeLibLoaded) {
    final error = _nativeUnavailableMessage();
    _nativeSelfTestError = error;
    return SaplingNativeSelfTestResult(
      loaded: false,
      symbolsReady: false,
      feeMatchesPolicy: false,
      error: error,
    );
  }

  try {
    final version = getVersion();
    if (version == 'not loaded' || version == 'unknown') {
      final error = 'Native version symbol returned $version';
      _nativeSelfTestError = error;
      return SaplingNativeSelfTestResult(
        loaded: true,
        symbolsReady: false,
        feeMatchesPolicy: false,
        version: version,
        error: error,
      );
    }

    final nativeFee = estimateFee(numSpends: 1, numOutputs: 1);
    final expectedFee = PivxFeePolicy.saplingFee(
      saplingInputs: 1,
      saplingOutputs: 1,
    );
    if (nativeFee != expectedFee) {
      final error =
          'Native fee policy mismatch: native=$nativeFee expected=$expectedFee';
      _nativeSelfTestError = error;
      return SaplingNativeSelfTestResult(
        loaded: true,
        symbolsReady: true,
        feeMatchesPolicy: false,
        version: version,
        error: error,
      );
    }

    _nativeSelfTestError = null;
    return SaplingNativeSelfTestResult(
      loaded: true,
      symbolsReady: true,
      feeMatchesPolicy: true,
      version: version,
    );
  } catch (e) {
    final error = e.toString();
    _nativeSelfTestError = error;
    return SaplingNativeSelfTestResult(
      loaded: true,
      symbolsReady: false,
      feeMatchesPolicy: false,
      error: error,
    );
  }
}

bool validateAddress(String address, {bool isTestnet = false}) {
  _ensureLoaded();
  if (!_nativeLibLoaded) return false;

  final addressPtr = address.toNativeUtf8();
  try {
    return _validateAddress(addressPtr, isTestnet ? 1 : 0) == 1;
  } finally {
    zeroNativeUtf8String(addressPtr, address);
    malloc.free(addressPtr);
  }
}

int estimateFee({
  int numSpends = 0,
  int numOutputs = 0,
  int numTransparentInputs = 0,
  int numTransparentOutputs = 0,
}) {
  _ensureLoaded();
  if (!_nativeLibLoaded) throw StateError(_nativeUnavailableMessage());
  return _estimateFee(
      numSpends, numOutputs, numTransparentInputs, numTransparentOutputs);
}

/// Verify a server-supplied witness by recomputing its Sapling Merkle root
/// locally and comparing it to the expected anchor.
///
/// [witnessHex]: 32 concatenated sibling hashes as hex (2048 hex chars), the
/// same serialization passed to the native transaction builder.
/// [cmuHex]: 32-byte note commitment as hex.
/// [anchorHex]: 32-byte expected anchor (Merkle root) as hex.
/// [position]: Position of the note in the commitment tree.
///
/// Returns true when the recomputed root equals the anchor, false on a clean
/// mismatch. Throws [StateError] when verification itself fails (native
/// library unavailable, malformed or non-canonical inputs).
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

bool hasProvingParams(String path) {
  _ensureLoaded();
  if (!_nativeLibLoaded) return false;
  final pathPtr = path.toNativeUtf8();
  try {
    return _hasProvingParams(pathPtr) == 1;
  } finally {
    zeroNativeUtf8String(pathPtr, path);
    malloc.free(pathPtr);
  }
}

/// Load the Groth16 proving params (~50 MB) into memory; call once before
/// building transactions. Returns false on failure; see [getLastError].
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

bool isProverInitialized() {
  _ensureLoaded();
  if (!_nativeLibLoaded) return false;
  return _isProverInitialized() == 1;
}

/// Free the prover and release memory (~50MB).
void disposeProver() {
  _ensureLoaded();
  if (!_nativeLibLoaded) return;
  _disposeProver();
}

/// Spendable notes from the sync state (all fields needed to build a tx).
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

/// The single unspent note at [position] (the one just decrypted), or null.
/// Avoids re-serializing every note via getSpendableNotes on each match.
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

/// Restore a note from persistent storage (same fields as getSpendableNotes);
/// returns false on failure.
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

/// Build a shielded transaction from explicit notes and witnesses.
/// [notesJson] is a JSON array of SpendableNoteData; [anchorHex] is the 32-byte
/// Merkle root as hex. Returns a Map of tx details or throws on error.
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

/// Build a transparent-to-shielded (t-to-z, shield) transaction.
/// [utxosJson] is a JSON array of UTXOs (txid, vout, value, script_pubkey hex,
/// private_key 32-byte hex); [changeAddress]/[change] is an optional transparent
/// change output. Amounts must balance exactly: sum(utxos) = amount + change + fee.
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

/// PIVX Sapling key manager handle; manages shielded keys derived from a seed.
class SaplingKeys {
  final int _handle;
  bool _disposed = false;

  SaplingKeys._(this._handle);

  static SaplingKeys fromSeed(Uint8List seed, {bool isTestnet = false}) {
    _ensureLoaded();
    if (!_nativeLibLoaded) {
      throw Exception('Native library not available: $_nativeLibError');
    }

    final seedPtr = malloc<Uint8>(seed.length);
    try {
      seedPtr.asTypedList(seed.length).setAll(0, seed);

      final handle = _initKeys(seedPtr, seed.length, isTestnet ? 1 : 0);
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

    final ptr = _getDefaultAddress(_handle);
    if (ptr == nullptr) {
      throw Exception(getLastError() ?? 'Failed to get address');
    }

    final address = ptr.toDartString();
    _freeString(ptr);
    return address;
  }

  String deriveAddress(int index) {
    _checkDisposed();

    final ptr = _deriveAddress(_handle, index);
    if (ptr == nullptr) {
      throw Exception(getLastError() ?? 'Failed to derive address');
    }

    final address = ptr.toDartString();
    _freeString(ptr);
    return address;
  }

  /// Full viewing key (for watch-only wallets).
  String getViewingKey() {
    _checkDisposed();

    final ptr = _getViewingKey(_handle);
    if (ptr == nullptr) {
      throw Exception(getLastError() ?? 'Failed to get viewing key');
    }

    final key = ptr.toDartString();
    _freeString(ptr);
    return key;
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

/// PIVX Sapling sync engine handle; manages block sync and note tracking.
class SaplingSyncEngine {
  final int _handle;
  bool _disposed = false;

  SaplingSyncEngine._(this._handle);

  int get handle => _handle;

  factory SaplingSyncEngine({bool isTestnet = false}) {
    _ensureLoaded();
    if (!_nativeLibLoaded) {
      throw Exception(_nativeUnavailableMessage());
    }
    final handle = _initSyncEngine(isTestnet ? 1 : 0);
    if (handle < 0) {
      throw Exception(getLastError() ?? 'Failed to initialize sync engine');
    }
    return SaplingSyncEngine._(handle);
  }

  int get syncHeight {
    _checkDisposed();
    return _getSyncHeight(_handle);
  }

  /// In satoshis.
  int get shieldedBalance {
    _checkDisposed();
    return _getShieldedBalance(_handle);
  }

  int get unspentNoteCount {
    _checkDisposed();
    return _getUnspentNoteCount(_handle);
  }

  /// For rescan.
  void reset() {
    _checkDisposed();
    _resetSync(_handle);
  }

  void setSyncHeight(int height) {
    _checkDisposed();
    _setSyncHeight(_handle, height);
  }

  /// Trial-decrypt a Sapling output with the wallet's incoming viewing key.
  /// Returns the note value in zatoshis on success, 0 otherwise.
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

  /// Mark our note spent if [nullifier] matches; returns true if one was marked.
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
