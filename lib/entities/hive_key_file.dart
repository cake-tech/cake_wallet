import 'dart:io';

import 'package:path/path.dart' as p;

const hiveKeyFileDirectoryName = '.hive_keys';

File hiveKeyFile(Directory appDir, String name) =>
    File(p.join(appDir.path, hiveKeyFileDirectoryName, name));

Future<String?> readHiveKeyFile(Directory appDir, String name) async {
  try {
    final file = hiveKeyFile(appDir, name);
    if (!await file.exists()) {
      return null;
    }
    final value = (await file.readAsString()).trim();
    return value.isEmpty ? null : value;
  } catch (_) {
    return null;
  }
}

Future<void> writeHiveKeyFile(Directory appDir, String name, String value) async {
  final file = hiveKeyFile(appDir, name);
  await file.parent.create(recursive: true);
  await file.writeAsString(value, flush: true);
  if (!Platform.isWindows) {
    await Process.run('chmod', ['600', file.path]);
  }
}
