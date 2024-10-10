import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cw_mweb_platform_interface.dart';

/// An implementation of [CwMwebPlatform] that uses method channels.
class MethodChannelCwMweb extends CwMwebPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cw_mweb');

  @override
  Future<int?> start(String dataDir, String nodeUri) async {
    final result =
        await methodChannel.invokeMethod<int>('start', {'dataDir': dataDir, 'nodeUri': nodeUri});
    return result;
  }

  @override
  Future<void> stop() async {
    await methodChannel.invokeMethod<void>('stop');
  }

  @override
  Future<String?> address(Uint8List scanSecret, Uint8List spendPub, int index) async {
    final result = await methodChannel.invokeMethod<String>('address', {
      'scanSecret': scanSecret,
      'spendPub': spendPub,
      'index': index,
    });
    return result;
  }
}
