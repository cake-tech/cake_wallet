import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cw_haven/cw_haven.dart';

void main() {
  const MethodChannel channel = MethodChannel('cw_haven');

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
    expect(await CwHaven.platformVersion, '42');
  });
}
