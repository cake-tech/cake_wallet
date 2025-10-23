import 'dart:io';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('com.cake_wallet/native_utils');

Future<void> setDefaultMinimumWindowSize() async {
  if (!Platform.isMacOS) return;

  try {
    // A small delay to confirm that our native platform channels are ready
    await Future.delayed(const Duration(milliseconds: 100));

    final result = await _channel.invokeMethod(
      'setMinWindowSize',
      {'width': 500, 'height': 700},
    ) as bool;

    if (!result) {
      printV("Failed to set minimum window size.");
    }
  } on PlatformException catch (e) {
    printV("Failed to set minimum window size: '${e.message}'.");
  } on MissingPluginException catch (e) {
    printV("Native utils plugin not available yet: '${e.message}'. Retrying...");
    // We give it a longer delay this time around, and then retry
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final result = await _channel.invokeMethod(
        'setMinWindowSize',
        {'width': 500, 'height': 700},
      ) as bool;

      if (!result) {
        printV("Failed to set minimum window size on retry.");
      }
    } catch (retryError) {
      printV("Failed to set minimum window size after retry: '$retryError'.");
    }
  }
}
