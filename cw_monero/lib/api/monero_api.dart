import 'dart:ffi';
import 'dart:io';

final DynamicLibrary moneroApi = Platform.isWindows
    ? DynamicLibrary.open("libcw_monero.dll")
    : Platform.environment.containsKey('FLUTTER_TEST')
        ? DynamicLibrary.open(
        'crypto_plugins/flutter_libmonero/scripts/linux/build/libcw_monero.so');
        : Platform.isAndroid || Platform.isLinux
            ? DynamicLibrary.open("libcw_monero.so")
            : DynamicLibrary.open("cw_monero.framework/cw_monero");
