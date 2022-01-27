import 'package:flutter/services.dart';

class WakeLock {
  static const _utils = const MethodChannel('com.cake_wallet/native_utils');

  Future<void> enableWake() async {
    try {
      await _utils.invokeMethod<bool>('enableWakeScreen');
    } on PlatformException catch (_) {
      print('Failed enabling screen wakelock');
    }
  }

  Future<void> disableWake() async {
    try {
      await _utils.invokeMethod<bool>('disableWakeScreen');
    } on PlatformException catch (_) {
      print('Failed enabling screen wakelock');
    }
  }
}
