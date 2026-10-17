import "dart:io";

import "package:flutter/services.dart";

/// iOS only: the Keychain OSStatus of the same query flutter_secure_storage runs for `read(key)`.
/// The plugin drops that status and reports every failure as null. Returns null on other platforms
/// or when the status can't be fetched.
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
