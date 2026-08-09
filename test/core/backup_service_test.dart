import 'dart:io';

import 'package:cake_wallet/core/backup_archive_path.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('BackupService.resolveSafeArchivePath', () {
    late Directory base;

    setUpAll(() {
      base = Directory.systemTemp.createTempSync('cw1607-backup-test');
    });

    tearDownAll(() {
      if (base.existsSync()) {
        base.deleteSync(recursive: true);
      }
    });

    test('resolves benign nested file and directory entries under the base path', () {
      expect(
        resolveSafeArchivePath(base.path, 'wallets/BTC/addresses.json'),
        p.join(base.path, 'wallets/BTC/addresses.json'),
      );
      expect(
        resolveSafeArchivePath(base.path, 'wallets/BTC/'),
        p.join(base.path, 'wallets/BTC'),
      );
    });

    test('rejects ".." traversal in any position, in either path syntax', () {
      expect(
        () => resolveSafeArchivePath(base.path, '../evil'),
        throwsFormatException,
      );
      expect(
        () => resolveSafeArchivePath(base.path, 'sub/../../evil'),
        throwsFormatException,
      );
      expect(
        () => resolveSafeArchivePath(base.path, 'wallets/a/../b'),
        throwsFormatException,
      );
      expect(
        () => resolveSafeArchivePath(base.path, r'..\..\evil'),
        throwsFormatException,
      );
    });

    test('rejects absolute entry names in POSIX and Windows syntax', () {
      expect(
        () => resolveSafeArchivePath(base.path, '/etc/passwd'),
        throwsFormatException,
      );
      expect(() => resolveSafeArchivePath(base.path, '/'), throwsFormatException);
      expect(
        () => resolveSafeArchivePath(base.path, r'C:\Windows\System32\evil'),
        throwsFormatException,
      );
      expect(
        () => resolveSafeArchivePath(base.path, 'C:/evil'),
        throwsFormatException,
      );
    });

    test('rejects empty entry names', () {
      expect(() => resolveSafeArchivePath(base.path, ''), throwsFormatException);
    });
  });
}
