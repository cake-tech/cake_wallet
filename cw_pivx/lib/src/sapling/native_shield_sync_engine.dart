/// Owns the native Sapling sync engine handle (Rust FFI).
///
/// The scan loop lives in [ShieldSyncEngineWrapper]; this type only constructs
/// and disposes the underlying [ffi.SaplingSyncEngine] and exposes its handle.

import 'package:cw_pivx/src/sapling/sapling_ffi.dart' as ffi;

class NativeShieldSyncEngine {
  final ffi.SaplingSyncEngine _engine;

  NativeShieldSyncEngine._(this._engine);

  factory NativeShieldSyncEngine({bool isTestnet = false}) =>
      NativeShieldSyncEngine._(ffi.SaplingSyncEngine(isTestnet: isTestnet));

  ffi.SaplingSyncEngine get nativeEngine => _engine;

  int get handle => _engine.handle;

  void dispose() => _engine.dispose();
}
