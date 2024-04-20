import 'package:flutter_test/flutter_test.dart';
import 'package:cw_mweb/cw_mweb.dart';
import 'package:cw_mweb/cw_mweb_platform_interface.dart';
import 'package:cw_mweb/cw_mweb_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCwMwebPlatform
    with MockPlatformInterfaceMixin
    implements CwMwebPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CwMwebPlatform initialPlatform = CwMwebPlatform.instance;

  test('$MethodChannelCwMweb is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCwMweb>());
  });

  test('getPlatformVersion', () async {
    CwMweb cwMwebPlugin = CwMweb();
    MockCwMwebPlatform fakePlatform = MockCwMwebPlatform();
    CwMwebPlatform.instance = fakePlatform;

    expect(await cwMwebPlugin.getPlatformVersion(), '42');
  });
}
