import 'dart:ffi';
import 'dart:io';

final DynamicLibrary wowneroApi = Platform.isWindows
    ? DynamicLibrary.open("libcw_wownero.dll")
    : io.Platform.environment.containsKey('FLUTTER_TEST')
        ? DynamicLibrary.open(
        'crypto_plugins/flutter_libmonero/scripts/linux/build/libcw_wownero.so');
        : Platform.isAndroid || Platform.isLinux
            ? DynamicLibrary.open("libcw_wownero.so")
            : DynamicLibrary.open("cw_wownero.framework/cw_wownero");