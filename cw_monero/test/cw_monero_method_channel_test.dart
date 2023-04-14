import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cw_monero/cw_monero_method_channel.dart';

void main() {
  MethodChannelCwMonero platform = MethodChannelCwMonero();
  const MethodChannel channel = MethodChannel('cw_monero');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
