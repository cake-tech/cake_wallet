import 'dart:io';

File getMoneroCBinary() {
  if (Platform.isWindows)
    return File(
        '../scripts/monero_c/release/monero/x86_64-w64-mingw32_libwallet2_api_c.dll');
  if (Platform.isMacOS) return File('../macos/monero_libwallet2_api_c.dylib');
  return File('../scripts/monero_c/release/monero/x86_64-linux-gnu_libwallet2_api_c.so');
}

String get moneroCBinaryName {
  if (Platform.isWindows)
    return "monero_libwallet2_api_c.dll";
  if (Platform.isMacOS) return "monero_libwallet2_api_c.dylib";
  return "/usr/lib/monero_libwallet2_api_c.so";
}
