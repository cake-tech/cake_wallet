import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cw_salvium_method_channel.dart';

abstract class CwSalviumPlatform extends PlatformInterface {
  /// Constructs a CwSalviumPlatform.
  CwSalviumPlatform() : super(token: _token);

  static final Object _token = Object();

  static CwSalviumPlatform _instance = MethodChannelCwSalvium();

  /// The default instance of [CwSalviumPlatform] to use.
  ///
  /// Defaults to [MethodChannelCwSalvium].
  static CwSalviumPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CwSalviumPlatform] when
  /// they register themselves.
  static set instance(CwSalviumPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
