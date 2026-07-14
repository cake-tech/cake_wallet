import 'dart:io';
import 'package:path/path.dart' as p;

File getMoneroCBinary() {
  final baseDir = Directory('../scripts/monero_c/release');

  final versionDir = baseDir.listSync().whereType<Directory>().map((d) => d.path).firstWhere(
        (path) => p.basename(path).startsWith('v'),
      );

  if (Platform.isWindows) {
    return File(p.join(versionDir, 'x86_64-w64-mingw32', 'libmonero_wallet2_api_c.dll'));
  }
  if (Platform.isMacOS) {
    return File(p.join(versionDir, 'macos', 'libmonero_wallet2_api_c.dylib'));
  }
  return File(p.join(versionDir, 'x86_64-linux-gnu', 'libmonero_wallet2_api_c.so'));
}

String get moneroCBinaryName {
  if (Platform.isWindows) return "libmonero_wallet2_api_c.dll";
  if (Platform.isMacOS) return "libmonero_wallet2_api_c.dylib";
  return "/usr/lib/libmonero_wallet2_api_c.so";
}
