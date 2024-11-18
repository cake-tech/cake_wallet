import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cw_wownero_method_channel.dart';

abstract class CwWowneroPlatform extends PlatformInterface {
  /// Constructs a CwWowneroPlatform.
  CwWowneroPlatform() : super(token: _token);

  static final Object _token = Object();

  static CwWowneroPlatform _instance = MethodChannelCwWownero();

  /// The default instance of [CwWowneroPlatform] to use.
  ///
  /// Defaults to [MethodChannelCwWownero].
  static CwWowneroPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CwWowneroPlatform] when
  /// they register themselves.
  static set instance(CwWowneroPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
