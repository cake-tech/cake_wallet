import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cw_wownero_platform_interface.dart';

/// An implementation of [CwWowneroPlatform] that uses method channels.
class MethodChannelCwWownero extends CwWowneroPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cw_wownero');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
