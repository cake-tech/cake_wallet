import 'dart:ffi';
import 'dart:io';

final DynamicLibrary moneroApi = Platform.isAndroid || Platform.isLinux
    ? DynamicLibrary.open("libcw_monero.so")
    : DynamicLibrary.open("cw_monero.framework/cw_monero");
