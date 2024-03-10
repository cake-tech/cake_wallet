import 'dart:ffi';
import 'dart:io';

final DynamicLibrary zanoApi = Platform.isAndroid
    ? DynamicLibrary.open('libcw_zano.so')
    : DynamicLibrary.open('cw_zano.framework/cw_zano');
