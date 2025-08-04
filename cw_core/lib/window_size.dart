import 'dart:io';

import 'package:cw_core/utils/print_verbose.dart';
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
      printV("Failed to set minimum window size.");
    }
  } on PlatformException catch (e) {
    printV("Failed to set minimum window size: '${e.message}'.");
  }
}
