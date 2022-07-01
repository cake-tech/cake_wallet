
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterLibmonero {
  static const MethodChannel _channel =
      const MethodChannel('flutter_libmonero');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
