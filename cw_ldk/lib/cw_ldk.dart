import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
// import 'package:isolate/ports.dart';
import 'ffi.dart' as native;
import 'package:path_provider/path_provider.dart';

// typedef _callback_Dart = Void Function();
// typedef _callback_C = Void Function();
typedef _print_C = Void Function(Pointer<Utf8>);

class CwLdk {
  static const MethodChannel _channel = const MethodChannel('cw_ldk');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> getAppDocDirPath() async {
    final Directory _appDocDir = await getApplicationDocumentsDirectory();
    return _appDocDir.path;
  }

  static Future<String> createFolderInAppDocDir(String folderName) async {
    //Get this App Document Directory
    final Directory _appDocDir = await getApplicationDocumentsDirectory();
    //App Document Directory + folder name
    final Directory _appDocDirFolder =
        Directory('${_appDocDir.path}/$folderName/');
    // final Directory _appDocDirFolder = Directory('$folderName');

    if (await _appDocDirFolder.exists()) {
      //if folder already exists return path
      return _appDocDirFolder.path;
    } else {
      //if folder not exists create folder and then return its path
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      return _appDocDirNewFolder.path;
    }
  }

  static Future<bool> deleteFolder(String folderName) async {
    //Get this App Document Directory
    final Directory _appDocDir = await getApplicationDocumentsDirectory();
    //App Document Directory + folder name
    final Directory _appDocDirFolder =
        Directory('${_appDocDir.path}/$folderName/');
    // final Directory _appDocDirFolder = Directory('$folderName');

    if (await _appDocDirFolder.exists()) {
      //if folder has content
      await for (var entity
          in _appDocDirFolder.list(recursive: true, followLinks: false)) {
        print("delete: ${entity.path}");
        await File(entity.path).delete();
      }
      await _appDocDirFolder.delete();
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> listFilesInFolder(String folderName) async {
    //Get this App Document Directory
    final Directory _appDocDir = await getApplicationDocumentsDirectory();

    //App Document Directory + folder name
    final Directory _appDocDirFolder =
        Directory('${_appDocDir.path}/$folderName/');

    if (await _appDocDirFolder.exists()) {
      //if folder already exists return path
      await for (var entity
          in _appDocDirFolder.list(recursive: true, followLinks: false)) {
        print("path: ${entity.path}");
      }
      return true;
    } else {
      return false;
    }
  }

  static void callback() {
    print("calling native function from flutter.......");
  }

  static void wrappedPrint(Pointer<Utf8> arg) {
    final res = arg.toDartString();
    print(res);
  }

  static Future<String> startLDK(String rpcInfo, int port, String network,
      String nodeName, String address, String mnemonicKeyPhrase) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final wrappedPrintPointer = Pointer.fromFunction<_print_C>(wrappedPrint);

    final _res = native.start_ldk(
        rpcInfo.toNativeUtf8(),
        appDocDir.path.toNativeUtf8(),
        port,
        network.toNativeUtf8(),
        nodeName.toNativeUtf8(),
        address.toNativeUtf8(),
        mnemonicKeyPhrase.toNativeUtf8(),
        wrappedPrintPointer);

    final res = _res.toDartString();
    calloc.free(_res);
    return res;
  }

  static String sendMessage(String msg) {
    final _res = native.send_message(msg.toNativeUtf8());

    final res = _res.toDartString();
    calloc.free(_res);
    return res;
  }

  static String nodeInfo() {
    final res = sendMessage("nodeinfo");
    return res;
  }

  static String connectPeer(String url) {
    final res = sendMessage("connectpeer $url");
    return res;
  }

  // static Future<String> testLDKAsync(String rpcInfo) async {
  //   final completer = Completer<String>();
  //   final sendPort = singleCompletePort<String, String>(completer);
  //   final port = sendPort.nativePort;

  //   final Directory _appDocDir = await getApplicationDocumentsDirectory();

  //   final res = native.test_ldk_async(
  //       port, rpcInfo.toNativeUtf8(), _appDocDir.path.toNativeUtf8());

  //   if (res != 1) {
  //     _throwError();
  //   }

  //   return completer.future;
  // }

  // static String testLDKBlocking(String path) {
  //   // final callbackPointer = Pointer.fromFunction<_callback_C>(callback);
  //   final wrappedPrintPointer = Pointer.fromFunction<_print_C>(wrappedPrint);

  //   final _res =
  //       native.test_ldk_block(path.toNativeUtf8(), wrappedPrintPointer);
  //   final res = _res.toDartString();
  //   calloc.free(_res);
  //   return res;
  // }

  // static void ffiChannels() {
  //   final wrappedPrintPointer = Pointer.fromFunction<_print_C>(wrappedPrint);
  //   native.ffi_channels(wrappedPrintPointer);
  // }

  // static void ldkChannels() {
  //   final wrappedPrintPointer = Pointer.fromFunction<_print_C>(wrappedPrint);
  //   native.ldk_channels(wrappedPrintPointer);
  // }

  static void storeDartPostCobject(
    Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr,
  ) {
    native.store_dart_post_cobject(ptr);
  }

  // static void _throwError() {
  //   final length = native.last_error_length();
  //   final Pointer<Utf8> message = calloc.allocate(length);
  //   native.error_message_utf8(message, length);
  //   final error = message.toDartString();
  //   print(error);
  //   throw Exception(error);
  // }
}
