import 'dart:ffi';
import 'dart:io';

DynamicLibrary get moneroApi {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    // DynamicLibrary.open(
    //     'scripts/linux/build/jsoncpp/build/src/lib_json/libjsoncpp.so');
    // DynamicLibrary.open(
    //     'scripts/linux/build/jsoncpp/build/src/lib_json/libjsoncpp.so.1');
    // DynamicLibrary.open(
    //     'scripts/linux/build/jsoncpp/build/src/lib_json/libjsoncpp.so.1.7.4');
    //
    // DynamicLibrary.open(
    //     'scripts/linux/build/libsecret/_build/libsecret/libsecret-1.so');
    // DynamicLibrary.open(
    //     'scripts/linux/build/libsecret/_build/libsecret/libsecret-1.so.0');
    // DynamicLibrary.open(
    //     'scripts/linux/build/libsecret/_build/libsecret/libsecret-1.so.0.0.0');

    return Platform.isWindows
        ? DynamicLibrary.open("libcw_monero.dll")
        : Platform.isAndroid || Platform.isLinux
            ? DynamicLibrary.open('crypto_plugins/flutter_libmonero/scripts/linux/build/libcw_monero.so')
            : DynamicLibrary.open("cw_monero.framework/cw_monero");
  }
  return Platform.isWindows
      ? DynamicLibrary.open("libcw_monero.dll")
      : Platform.isAndroid || Platform.isLinux
          ? DynamicLibrary.open("libcw_monero.so")
          : DynamicLibrary.open("cw_monero.framework/cw_monero");
}
