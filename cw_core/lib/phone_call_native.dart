import "dart:io";

import "package:flutter/services.dart";

bool get _canDetectPhoneCalls => Platform.isIOS || Platform.isAndroid;

Future<bool> isOnPhoneCallNative() async {
  if (!_canDetectPhoneCalls) {
    return false;
  }

  try {
    const utils = MethodChannel("com.cake_wallet/native_utils");
    return await utils.invokeMethod<bool>("is_on_phone_call") ?? false;
  } catch (_) {
    return false;
  }
}

final Stream<bool> phoneCallStatusNative = _canDetectPhoneCalls
    ? const EventChannel("com.cake_wallet/phone_call_status")
        .receiveBroadcastStream()
        .map((isOnPhoneCall) => isOnPhoneCall == true)
    : const Stream<bool>.empty();
