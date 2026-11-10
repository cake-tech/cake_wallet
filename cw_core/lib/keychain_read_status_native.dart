import "dart:io";

import "package:flutter/services.dart";

Future<int?> keychainReadStatusNative(String key) async {
  if (!Platform.isIOS) {
    return null;
  }

  try {
    const utils = MethodChannel("com.cake_wallet/native_utils");
    return await utils.invokeMethod<int>("keychain_read_status", {"key": key});
  } catch (_) {
    return null;
  }
}
