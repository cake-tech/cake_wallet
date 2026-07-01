import 'package:flutter/services.dart';

Future<void> setIsAppSecureNative(bool isAppSecure) async {
  try {
    final utils = const MethodChannel('com.cake_wallet/native_utils');

    await utils.invokeMethod<Uint8List>('setIsAppSecure', {'isAppSecure': isAppSecure});
  } catch (_) {}
}
