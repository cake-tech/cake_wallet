import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cw_nerva_method_channel.dart';

abstract class CwNervaPlatform extends PlatformInterface {
  /// Constructs a CwNervaPlatform.
  CwNervaPlatform() : super(token: _token);

  static final Object _token = Object();

  static CwNervaPlatform _instance = MethodChannelCwNerva();

  /// The default instance of [CwNervaPlatform] to use.
  ///
  /// Defaults to [MethodChannelCwNerva].
  static CwNervaPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CwNervaPlatform] when
  /// they register themselves.
  static set instance(CwNervaPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
