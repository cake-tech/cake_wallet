/// Native Sapling key manager backed by the Rust FFI bindings.

import 'dart:typed_data';
import 'package:cw_pivx/src/sapling/sapling_constants.dart';
import 'package:cw_pivx/src/sapling/sapling_ffi.dart' as ffi;

/// Core key operations; the factories wrap this into the full wallet interface.
class NativeSaplingKeyManager {
  final ffi.SaplingKeys _keys;
  final bool _isTestnet;
  int _nextDiversifierIndex = 0;

  NativeSaplingKeyManager._(this._keys, this._isTestnet);

  static Future<NativeSaplingKeyManager> fromSeed(
    Uint8List seed, {
    bool isTestnet = false,
  }) async {
    final keys = ffi.SaplingKeys.fromSeed(seed, isTestnet: isTestnet);
    return NativeSaplingKeyManager._(keys, isTestnet);
  }

  Future<String> getDefaultAddress() async {
    return _keys.getDefaultAddress();
  }

  Future<String> deriveAddress(int index) async {
    return _keys.deriveAddress(index);
  }

  Future<String> getNextAddress() async {
    final address = _keys.deriveAddress(_nextDiversifierIndex);
    _nextDiversifierIndex++;
    return address;
  }

  Future<String> getFullViewingKey() async {
    return _keys.getViewingKey();
  }

  bool validateAddress(String address) {
    return ffi.validateAddress(address, isTestnet: _isTestnet);
  }

  bool get isTestnet => _isTestnet;

  String get paymentAddressHrp => _isTestnet
      ? PivxSaplingNetwork.testnetPaymentAddressHrp
      : PivxSaplingNetwork.mainnetPaymentAddressHrp;

  void dispose() {
    _keys.dispose();
  }

  ffi.SaplingKeys get nativeKeys => _keys;
}
