import 'package:flutter_test/flutter_test.dart';
import 'package:cw_monero/cw_monero.dart';
import 'package:cw_monero/cw_monero_platform_interface.dart';
import 'package:cw_monero/cw_monero_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCwMoneroPlatform
    with MockPlatformInterfaceMixin
    implements CwMoneroPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CwMoneroPlatform initialPlatform = CwMoneroPlatform.instance;

  test('$MethodChannelCwMonero is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCwMonero>());
  });

  test('getPlatformVersion', () async {
    CwMonero cwMoneroPlugin = CwMonero();
    MockCwMoneroPlatform fakePlatform = MockCwMoneroPlatform();
    CwMoneroPlatform.instance = fakePlatform;

    expect(await cwMoneroPlugin.getPlatformVersion(), '42');
  });
}
