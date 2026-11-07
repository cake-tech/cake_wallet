import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:cw_pivx/src/sapling/sapling_constants.dart';
import 'package:cw_pivx/src/sapling/sapling_factories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sapling proving parameter download', () {
    setUp(() {
      CakeTor.instance = CakeTorDisabled();
    });

    test('streams files to temp paths, verifies them, and renames finals',
        () async {
      final spendBytes = List<int>.generate(257, (i) => i % 251);
      final outputBytes = List<int>.generate(113, (i) => (i * 3) % 251);
      final server = await _serveParams(
        spendBytes: spendBytes,
        outputBytes: outputBytes,
      );
      final dir = await Directory.systemTemp.createTemp('pivx_params_test_');
      final progress = <double>[];

      try {
        await SaplingTransactionBuilder.downloadProvingParamsToPath(
          path: dir.path,
          onProgress: progress.add,
          mirrors: [_serverBase(server)],
          spendParamsSize: spendBytes.length,
          spendParamsHash: sha256.convert(spendBytes).toString(),
          outputParamsSize: outputBytes.length,
          outputParamsHash: sha256.convert(outputBytes).toString(),
        );

        final spendFile =
            File('${dir.path}/${SaplingParams.spendParamsFileName}');
        final outputFile =
            File('${dir.path}/${SaplingParams.outputParamsFileName}');

        expect(await spendFile.readAsBytes(), spendBytes);
        expect(await outputFile.readAsBytes(), outputBytes);
        expect(await File('${spendFile.path}.download').exists(), isFalse);
        expect(await File('${outputFile.path}.download').exists(), isFalse);
        expect(progress.last, 1.0);
      } finally {
        await server.close(force: true);
        await dir.delete(recursive: true);
      }
    });

    test('deletes temp files when verification fails', () async {
      final spendBytes = List<int>.filled(16, 7);
      final outputBytes = List<int>.filled(16, 9);
      final server = await _serveParams(
        spendBytes: spendBytes,
        outputBytes: outputBytes,
      );
      final dir = await Directory.systemTemp.createTemp('pivx_params_bad_');

      try {
        await expectLater(
          SaplingTransactionBuilder.downloadProvingParamsToPath(
            path: dir.path,
            onProgress: (_) {},
            mirrors: [_serverBase(server)],
            spendParamsSize: spendBytes.length,
            spendParamsHash: '00',
            outputParamsSize: outputBytes.length,
            outputParamsHash: sha256.convert(outputBytes).toString(),
          ),
          throwsA(isA<Exception>()),
        );

        final spendFile =
            File('${dir.path}/${SaplingParams.spendParamsFileName}');
        expect(await spendFile.exists(), isFalse);
        expect(await File('${spendFile.path}.download').exists(), isFalse);
      } finally {
        await server.close(force: true);
        await dir.delete(recursive: true);
      }
    });
  });
}

Future<HttpServer> _serveParams({
  required List<int> spendBytes,
  required List<int> outputBytes,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) {
    final requestedFile =
        request.uri.pathSegments.isEmpty ? '' : request.uri.pathSegments.last;
    final bytes = requestedFile == SaplingParams.spendParamsFileName
        ? spendBytes
        : requestedFile == SaplingParams.outputParamsFileName
            ? outputBytes
            : null;

    if (bytes == null) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.close();
      return;
    }

    request.response.contentLength = bytes.length;
    request.response.add(bytes);
    request.response.close();
  });
  return server;
}

String _serverBase(HttpServer server) =>
    'http://${InternetAddress.loopbackIPv4.address}:${server.port}';
