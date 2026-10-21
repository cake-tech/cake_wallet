import "dart:io";

import "package:cw_core/db/sqlite.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class FakePathProviderPlatform extends PathProviderPlatform {
  FakePathProviderPlatform(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getApplicationCachePath() async => root;
}

Future<void> setUpTestDb(Directory dataRoot) async {
  if (dataRoot.existsSync()) {
    dataRoot.deleteSync(recursive: true);
  }
  dataRoot.createSync(recursive: true);
  Directory("${dataRoot.path}/cake_wallet").createSync(recursive: true);
  PathProviderPlatform.instance = FakePathProviderPlatform(dataRoot.absolute.path);

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await initDb();
}
