import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cw_xelis_platform_interface.dart';

/// An implementation of [CwXelisPlatform] that uses method channels.
class MethodChannelCwXelis extends CwXelisPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cw_xelis');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
