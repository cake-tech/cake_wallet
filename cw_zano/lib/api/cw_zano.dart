import 'dart:async';

import 'package:flutter/services.dart';

class CwZano {
  static const MethodChannel _channel = const MethodChannel('cw_zano');

  static Future<String> get platformVersion async {
    final String version =
        await _channel.invokeMethod<String>('getPlatformVersion') ?? '';
    return version;
  }
}
