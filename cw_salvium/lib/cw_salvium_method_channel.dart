import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cw_salvium_platform_interface.dart';

/// An implementation of [CwSalviumPlatform] that uses method channels.
class MethodChannelCwSalvium extends CwSalviumPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cw_salvium');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
