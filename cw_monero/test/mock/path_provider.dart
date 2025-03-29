import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  Future<String> getTemporaryPath() => throw UnimplementedError();

  Future<String> getApplicationSupportPath() => throw UnimplementedError();

  Future<String> getLibraryPath() => throw UnimplementedError();

  Future<String> getApplicationDocumentsPath() async => "./test/data";

  Future<String> getExternalStoragePath() => throw UnimplementedError();

  Future<List<String>> getExternalCachePaths() => throw UnimplementedError();

  Future<String> getDownloadsPath() => throw UnimplementedError();

  @override
  Future<String?> getApplicationCachePath() => throw UnimplementedError();

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) =>
      throw UnimplementedError();
}
