import 'dart:ffi';
import 'dart:io';

final DynamicLibrary salviumApi = Platform.isAndroid
    ? DynamicLibrary.open("libcw_salvium.so")
    : DynamicLibrary.open("cw_salvium.framework/cw_salvium");
