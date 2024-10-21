import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cw_mweb_method_channel.dart';

abstract class CwMwebPlatform extends PlatformInterface {
  /// Constructs a CwMwebPlatform.
  CwMwebPlatform() : super(token: _token);

  static final Object _token = Object();

  static CwMwebPlatform _instance = MethodChannelCwMweb();

  /// The default instance of [CwMwebPlatform] to use.
  ///
  /// Defaults to [MethodChannelCwMweb].
  static CwMwebPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CwMwebPlatform] when
  /// they register themselves.
  static set instance(CwMwebPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<int?> start(String dataDir, String nodeUri) {
    throw UnimplementedError('start() has not been implemented.');
  }

  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Future<String?> address(Uint8List scanSecret, Uint8List spendPub, int index) {
    throw UnimplementedError('address(int) has not been implemented.');
  }

  Future<String?> addresses(Uint8List scanSecret, Uint8List spendPub, int fromIndex, int toIndex) {
    throw UnimplementedError('addresses has not been implemented.');
  }
}
