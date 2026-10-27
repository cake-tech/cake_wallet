import "dart:convert";
import "dart:io";

import "package:cake_wallet/core/backup/app_backup_preferences.dart";
import "package:crypto/crypto.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  test("the last backup keeps its SHA-256 hash", () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = AppBackupPreferences(await SharedPreferences.getInstance());
    final record = AppBackupRecord(
      createdAt: DateTime(2026, 10, 26, 12, 30),
      sizeInBytes: 1024,
      sha256Hash: "ab" * 32,
    );

    await preferences.recordBackup(record);
    final restored = preferences.lastBackup!;
    expect(restored.createdAt, record.createdAt);
    expect(restored.sizeInBytes, 1024);
    expect(restored.sha256Hash, "ab" * 32);

    await preferences.recordBackup(AppBackupRecord(createdAt: DateTime(2026), sizeInBytes: 1));
    expect(preferences.lastBackup!.sha256Hash, isNull);
  });

  test("a record for a file takes its date, size and hash from the file", () async {
    final dir = Directory.systemTemp.createTempSync("app_backup_record_test");
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File("${dir.path}/backup.zip")..writeAsStringSync("backup");
    final modified = DateTime(2026, 10, 1, 9, 15);
    file.setLastModifiedSync(modified);

    final record = await AppBackupRecord.forFile(file);

    expect(record.createdAt, modified);
    expect(record.sizeInBytes, 6);
    expect(record.sha256Hash, sha256.convert(utf8.encode("backup")).toString());
  });
}
