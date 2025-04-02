import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cw_xelis_method_channel.dart';

abstract class CwXelisPlatform extends PlatformInterface {
  /// Constructs a CwXelisPlatform.
  CwXelisPlatform() : super(token: _token);

  static final Object _token = Object();

  static CwXelisPlatform _instance = MethodChannelCwXelis();

  /// The default instance of [CwXelisPlatform] to use.
  ///
  /// Defaults to [MethodChannelCwXelis].
  static CwXelisPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CwXelisPlatform] when
  /// they register themselves.
  static set instance(CwXelisPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
