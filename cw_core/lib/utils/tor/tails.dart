import 'package:cw_core/utils/tor/abstract.dart';

class CakeTorTails implements CakeTorInstance {
  @override
  bool get bootstrapped => true;

  @override
  bool get enabled => true;

  @override
  int get port => 9150;

  @override
  Future<void> start() async {}

  @override
  bool get started => true;

  @override
  Future<void> stop() async {}
}