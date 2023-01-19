import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cw_monero_method_channel.dart';

abstract class CwMoneroPlatform extends PlatformInterface {
  /// Constructs a CwMoneroPlatform.
  CwMoneroPlatform() : super(token: _token);

  static final Object _token = Object();

  static CwMoneroPlatform _instance = MethodChannelCwMonero();

  /// The default instance of [CwMoneroPlatform] to use.
  ///
  /// Defaults to [MethodChannelCwMonero].
  static CwMoneroPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CwMoneroPlatform] when
  /// they register themselves.
  static set instance(CwMoneroPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
