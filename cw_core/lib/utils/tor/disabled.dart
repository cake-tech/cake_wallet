import 'package:cw_core/utils/tor/abstract.dart';

class CakeTorDisabled implements CakeTorInstance {
  @override
  bool get bootstrapped => false;

  @override
  bool get enabled => false;

  @override
  int get port => -1;

  @override
  Future<void> start() => throw UnimplementedError();

  @override
  bool get started => false;

  @override
  Future<void> stop() => throw UnimplementedError();
}