import 'dart:io';

import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('com.cake_wallet/native_utils');

Future<void> setDefaultMinimumWindowSize() async {
  if (!Platform.isMacOS) return;

  try {
    final result = await _channel.invokeMethod(
      'setMinWindowSize',
      {'width': 500, 'height': 700},
    ) as bool;

    if (!result) {
      print("Failed to set minimum window size.");
    }
  } on PlatformException catch (e) {
    print("Failed to set minimum window size: '${e.message}'.");
  }
}
