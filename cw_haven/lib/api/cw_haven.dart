
import 'dart:async';

import 'package:flutter/services.dart';

class CwHaven {
  static const MethodChannel _channel =
      const MethodChannel('cw_haven');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod<String>('getPlatformVersion') ?? '';
    return version;
  }
}
