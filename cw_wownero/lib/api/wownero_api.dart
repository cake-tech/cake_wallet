import 'dart:ffi';
import 'dart:io';

DynamicLibrary get wowneroApi {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return DynamicLibrary.open(
        'crypto_plugins/flutter_libmonero/scripts/linux/build/libcw_wownero.so');
  }
  return Platform.isAndroid || Platform.isLinux
      ? DynamicLibrary.open("libcw_wownero.so")
      : DynamicLibrary.open("cw_wownero.framework/cw_wownero");
}
