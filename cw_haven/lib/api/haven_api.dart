import 'dart:ffi';
import 'dart:io';

final DynamicLibrary havenApi = Platform.isAndroid
    ? DynamicLibrary.open("libcw_haven.so")
    : DynamicLibrary.open("cw_haven.framework/cw_haven");