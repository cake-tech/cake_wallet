import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:cw_mweb/generated_bindings.g.dart';
import 'package:ffi/ffi.dart';

String libPath = (() {
  if (Platform.isWindows) return 'mweb.dll';
  if (Platform.isMacOS) return 'mweb.dylib';
  if (Platform.isIOS) return 'Mwebd.framework/Mwebd';
  if (Platform.isAndroid) return 'libmweb.so';
  return 'libmweb.so';
})();

class MWebFfi {
  late final MWebFlutter lib;

  MWebFfi() : lib = MWebFlutter(DynamicLibrary.open(libPath));

  static MWebFfi instance = MWebFfi();

  int start(String dataDir, String nodeUri) {
    final chain = "".toNativeUtf8().cast<Char>();
    final dataDir_ = dataDir.toNativeUtf8().cast<Char>();
    final nodeUri_ = nodeUri.toNativeUtf8().cast<Char>();
    final errMsgPtr = calloc<Pointer<Char>>();

    final port = lib.StartServer(chain, dataDir_, nodeUri_, errMsgPtr);
    if (port == 0) {
      final errMsg = errMsgPtr.value.cast<Utf8>().toDartString();
      print('Error starting server: $errMsg');
      calloc.free(errMsgPtr.value);
    }

    calloc.free(chain);
    calloc.free(dataDir_);
    calloc.free(nodeUri_);
    calloc.free(errMsgPtr);

    return port;
  }

  void stop() => lib.StopServer();

  String addresses(
      Uint8List scanSecret, Uint8List spendPub, int fromIndex, int toIndex) {
    final scanSecretPtr = malloc.allocate<Uint8>(scanSecret.length);
    for (int k = 0; k < scanSecret.length; k++) {
      scanSecretPtr[k] = scanSecret[k];
    }

    final spendPubKeyPtr = malloc.allocate<Uint8>(spendPub.length);
    for (int k = 0; k < spendPub.length; k++) {
      spendPubKeyPtr[k] = spendPub[k];
    }

    final Pointer<Char> resultPtr = lib.Addresses(
      scanSecretPtr.cast(),
      scanSecret.length,
      spendPubKeyPtr.cast(),
      spendPub.length,
      fromIndex,
      toIndex,
    );

    final result = resultPtr.cast<Utf8>().toDartString();

    malloc.free(scanSecretPtr);
    malloc.free(spendPubKeyPtr);
    malloc.free(resultPtr);

    return result;
  }
}
