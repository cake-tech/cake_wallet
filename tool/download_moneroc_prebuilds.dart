import 'dart:io';

import 'package:dio/dio.dart';
import 'package:archive/archive_io.dart';

final _dio = Dio();

final List<String> triplets = [
  "x86_64-linux-gnu", // linux desktop - majority of users onlinux
  // "i686-linux-gnu", // not supported by cake
  // "i686-meego-linux-gnu", // sailfishos (emulator)- not supported by cake
  // "aarch64-linux-gnu", // not (yet) supported by cake - (mostly) mobile linux
  // "aarch64-meego-linux-gnu", // sailfishos - not supported by cake
  "x86_64-linux-android",
  // "i686-linux-android", // not supported by monero_c - mostly old android emulators
  "aarch64-linux-android",
  "armv7a-linux-androideabi",
  // "i686-w64-mingw32", // 32bit windows - not supported by monero_c
  "x86_64-w64-mingw32",
  // "x86_64-apple-darwin11", // Intel macbooks (contrib) - not used by cake
  // "aarch64-apple-darwin11", // apple silicon macbooks (contrib) - not used by cake
  // "x86_64-host-apple-darwin", // not available on CI (yet)
  "aarch64-apple-darwin", // apple silicon macbooks
  "x86_64-apple-darwin", // intel macbooks
  "aarch64-apple-ios",
  "aarch64-apple-ios-simulator",
];

const _maxAttempts = 4;

bool _isTransient(Object error) {
  if (error is! DioException) {
    return false;
  }
  final status = error.response?.statusCode;
  if (status != null) {
    return status >= 500;
  }
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return true;
    default:
      return false;
  }
}

Future<T> _withRetry<T>(String what, Future<T> Function() operation) async {
  for (var attempt = 1;; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (attempt >= _maxAttempts || !_isTransient(error)) {
        rethrow;
      }
      final wait = Duration(seconds: 5 * attempt);
      print("  $what failed (attempt $attempt/$_maxAttempts): $error");
      print("  retrying in ${wait.inSeconds}s");
      await Future.delayed(wait);
    }
  }
}

Future<void> main() async {
  final resp = await _withRetry(
    "release list",
    () => _dio.get("https://api.github.com/repos/mrcyjanek/monero_c/releases"),
  );
  final data = resp.data[0];
  final tagName = data['tag_name'];
  print("Downloading artifacts for: ${tagName}");
  final assets = data['assets'] as List<dynamic>;
  final bundle = assets.firstWhere((asset) => asset["name"] == "release-bundle.zip");
  const bundlePath = "scripts/monero_c/release-bundle.zip";
  print("- downloading $bundlePath");
  await _withRetry(
    "release-bundle.zip",
    () => _dio.download(bundle["browser_download_url"] as String, bundlePath),
  );
  final archive = ZipDecoder().decodeStream(InputFileStream(bundlePath));
  for (final file in archive) {
    final parts = file.name.split("/");
    if (!file.isFile || parts.length != 3 || !triplets.contains(parts[1])) continue;
    final localFilename = "scripts/monero_c/release/${file.name}";
    print("  extracting $localFilename");
    Directory(File(localFilename).parent.path).createSync(recursive: true);
    final outputStream = OutputFileStream(localFilename);
    file.writeContent(outputStream);
    outputStream.closeSync();
  }
  File(bundlePath).deleteSync();
  if (Platform.isMacOS) {
    print("Generating ios framework");
    final result = Process.runSync(
      "bash",
      ["-c", "cd scripts/ios && ./gen_framework.sh && cd ../.."],
      environment: {"MONEROC_TAG": tagName as String},
    );
    print((result.stdout + result.stderr).toString().trim());
  }
}
