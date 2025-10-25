
import 'dart:async';

import 'package:flutter/services.dart';

class CwSharedExternal {
  static const MethodChannel _channel =
      const MethodChannel('cw_shared_external');

  static Future<String> get platformVersion async {
    final String version = (await _channel.invokeMethod('getPlatformVersion')).toString();
    return version;
  }
}
