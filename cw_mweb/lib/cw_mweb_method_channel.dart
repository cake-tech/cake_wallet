import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cw_mweb_platform_interface.dart';

/// An implementation of [CwMwebPlatform] that uses method channels.
class MethodChannelCwMweb extends CwMwebPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cw_mweb');

  @override
  Future<int?> start(String dataDir) async {
    final result = await methodChannel.invokeMethod<int>('start', {'dataDir': dataDir});
    return result;
  }
}
