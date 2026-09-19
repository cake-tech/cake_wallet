import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cw_pivx/src/sapling/sapling_factories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('writeAndVerifyProvingParam', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('pivx_params_test');
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    test('writes the file when size + SHA256 match', () async {
      final bytes = Uint8List.fromList(utf8.encode('pivx-sapling-synthetic'));
      final hash = sha256.convert(bytes).toString();
      final dest = '${tmp.path}/sapling-spend.params';

      await SaplingTransactionBuilderWrapper.writeAndVerifyProvingParam(
        bytes: bytes,
        destination: dest,
        expectedSize: bytes.length,
        expectedHash: hash,
      );

      expect(File(dest).existsSync(), isTrue);
      expect(File(dest).readAsBytesSync(), equals(bytes));
    });

    test('throws and removes the file on hash mismatch', () async {
      final bytes = Uint8List.fromList(utf8.encode('pivx-sapling-synthetic'));
      final dest = '${tmp.path}/sapling-output.params';

      await expectLater(
        SaplingTransactionBuilderWrapper.writeAndVerifyProvingParam(
          bytes: bytes,
          destination: dest,
          expectedSize: bytes.length,
          expectedHash: 'deadbeef' * 8, // wrong hash
        ),
        throwsA(isA<Exception>()),
      );

      expect(File(dest).existsSync(), isFalse);
    });

    test('throws on size mismatch', () async {
      final bytes = Uint8List.fromList(utf8.encode('pivx-sapling-synthetic'));
      final hash = sha256.convert(bytes).toString();
      final dest = '${tmp.path}/sapling-spend.params';

      await expectLater(
        SaplingTransactionBuilderWrapper.writeAndVerifyProvingParam(
          bytes: bytes,
          destination: dest,
          expectedSize: bytes.length + 1,
          expectedHash: hash,
        ),
        throwsA(isA<Exception>()),
      );

      expect(File(dest).existsSync(), isFalse);
    });
  });

  group('loadBundledParamOrNull', () {
    test('returns null for an absent asset (build without bundled params)',
        () async {
      final result = await SaplingTransactionBuilderWrapper.loadBundledParamOrNull(
        'packages/cw_pivx/assets/params/does-not-exist.params',
      );
      expect(result, isNull);
    });
  });
}
