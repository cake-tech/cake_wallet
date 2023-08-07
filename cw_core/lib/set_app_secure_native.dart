import 'package:flutter/services.dart';

void setIsAppSecureNative(bool isAppSecure) {
  try {
    final utils = const MethodChannel('com.cake_wallet/native_utils');

    utils.invokeMethod<Uint8List>('setIsAppSecure', {'isAppSecure': isAppSecure});
  } catch (_) {}
}
