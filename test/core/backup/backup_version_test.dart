import "dart:convert";
import "dart:io";

import "package:archive/archive_io.dart";
import "package:cake_wallet/core/backup_service.dart";
import "package:cake_wallet/core/backup_service_v3.dart";
import "package:cake_wallet/core/key_service.dart";
import "package:cake_wallet/core/secure_storage.dart";
import "package:cake_wallet/entities/transaction_description.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:mocktail/mocktail.dart";
import "package:shared_preferences/shared_preferences.dart";

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockKeyService extends Mock implements KeyService {}

class _MockTransactionDescriptionBox extends Mock implements Box<TransactionDescription> {}

void main() {
  late Directory tempDir;
  late BackupServiceV3 service;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync("backup_version_test");
    SharedPreferences.setMockInitialValues({});
    service = BackupServiceV3(
      _MockSecureStorage(),
      _MockTransactionDescriptionBox(),
      _MockKeyService(),
      await SharedPreferences.getInstance(),
    );
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  File rawFile(String name, List<int> bytes) =>
      File("${tempDir.path}/$name")..writeAsBytesSync(bytes);

  Future<File> zipWithMetadata(String name, Object? version) async {
    final metadata = File("${tempDir.path}/metadata.json")
      ..writeAsStringSync(
        jsonEncode({
          "version": version,
          "sha512sum": "",
          "chunks": <dynamic>[],
          "cakeVersion": "1.0.0",
        }),
      );
    final path = "${tempDir.path}/$name";
    final zip = ZipFileEncoder()..create(path);
    await zip.addFile(metadata, "metadata.json");
    await zip.close();
    return File(path);
  }

  test("detects v1 and v2 backups by their first byte", () {
    expect(service.getVersionFile(rawFile("v1.bin", [1, 9, 9])), BackupVersion.v1);
    expect(service.getVersionFile(rawFile("v2.bin", [2, 9, 9])), BackupVersion.v2);
  });

  test("detects v3 and v4 backups from metadata.json", () async {
    expect(service.getVersionFile(await zipWithMetadata("v3.zip", 3)), BackupVersion.v3);
    expect(service.getVersionFile(await zipWithMetadata("v4.zip", 4)), BackupVersion.v4);
  });

  test("reports unknown for future or malformed versions instead of throwing", () async {
    expect(service.getVersionFile(await zipWithMetadata("v9.zip", 9)), BackupVersion.unknown);
    expect(service.getVersionFile(await zipWithMetadata("bad.zip", "x")), BackupVersion.unknown);
    expect(service.getVersionFile(rawFile("other.bin", [7, 7])), BackupVersion.unknown);
  });

  test("zip without metadata is unknown and an empty file is invalid", () async {
    final path = "${tempDir.path}/plain.zip";
    final zip = ZipFileEncoder()..create(path);
    await zip.addFile(rawFile("readme.txt", utf8.encode("hello")), "README.txt");
    await zip.close();

    expect(service.getVersionFile(File(path)), BackupVersion.unknown);
    expect(
      () => service.getVersionFile(rawFile("empty.bin", [])),
      throwsA(isA<InvalidBackupException>()),
    );
  });

  test("importing an unknown version fails with UnknownBackupVersionException", () async {
    expect(
      () => service.importBackupFile(rawFile("other.bin", [7, 7]), "password"),
      throwsA(isA<UnknownBackupVersionException>()),
    );
  });
}
