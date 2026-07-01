import 'package:cw_core/utils/tor/abstract.dart';

class CakeTorSocks implements CakeTorInstance {
  CakeTorSocks(this.port);
  @override
  bool get bootstrapped => true;

  @override
  bool get enabled => true;

  @override
  int port;

  @override
  Future<void> start() async {}

  @override
  bool get started => true;

  @override
  Future<void> stop() async {}

  @override
  String toString() {
    return """
CakeTorSocks(
  port: $port,
  started: $started,
  bootstrapped: $bootstrapped,
  enabled: $enabled,
)
""";
  }
}