import "dart:io";

import "package:cw_core/db/sqlite.dart";
import "package:flutter_test/flutter_test.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

// Faking the documents dir keeps getAppDir() off the platform channel, so the
// tests run with a plain `flutter test` on any host and in CI.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

/// Opens a real database, built by the app's own [initDb], for the whole test
/// file. Using the real schema rather than hand-written DDL is the point: it
/// proves the migration created what the store queries.
void useSqliteDatabase(String scratchDirName) {
  final dataRoot = Directory("./test/data/$scratchDirName");

  setUpAll(() async {
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
    dataRoot.createSync(recursive: true);

    PathProviderPlatform.instance = _FakePathProviderPlatform(dataRoot.absolute.path);
    Directory("${dataRoot.path}/cake_wallet").createSync(recursive: true);

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initDb();
  });

  tearDownAll(() async {
    await db?.close();
    db = null;
    if (dataRoot.existsSync()) {
      dataRoot.deleteSync(recursive: true);
    }
  });
}
