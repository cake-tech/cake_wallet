import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cw_nerva_platform_interface.dart';

/// An implementation of [CwNervaPlatform] that uses method channels.
class MethodChannelCwNerva extends CwNervaPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cw_nerva');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
