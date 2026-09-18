import 'dart:io';

import 'package:cake_wallet/entities/hive_key_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_key_file_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('round-trips a hive key file and ignores missing files', () async {
    expect(await readHiveKeyFile(tempDir, 'ordersBoxKey'), isNull);

    await writeHiveKeyFile(tempDir, 'ordersBoxKey', '1,2,3,4');

    expect(await readHiveKeyFile(tempDir, 'ordersBoxKey'), '1,2,3,4');
    expect(hiveKeyFile(tempDir, 'ordersBoxKey').existsSync(), isTrue);
  });
}
