import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cw_monero_platform_interface.dart';

/// An implementation of [CwMoneroPlatform] that uses method channels.
class MethodChannelCwMonero extends CwMoneroPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cw_monero');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
