import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('com.cake_wallet/native_utils');

Future<void> requestDisableBatteryOptimization() async {
  try {
    await _channel.invokeMethod('disableBatteryOptimization');
  } on PlatformException catch (e) {
    print("Failed to disable battery optimization: '${e.message}'.");
  }
}

Future<bool> isBatteryOptimizationDisabled() async {
  try {
    final bool isDisabled = await _channel.invokeMethod('isBatteryOptimizationDisabled') as bool;
    print('It\'s actually disabled? $isDisabled');
    return isDisabled;
  } on PlatformException catch (e) {
    print("Failed to check battery optimization status: '${e.message}'.");
    return false;
  }
}
