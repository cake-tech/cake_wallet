import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const platform =
    const MethodChannel('com.cakewallet.cakewallet/legacy_wallet_migration');

Future<String> decrypt(Uint8List bytes,
        {required String key, required String salt}) async =>
    (await platform
        .invokeMethod<String>('decrypt', {'bytes': bytes, 'key': key, 'salt': salt}))!;

Future<dynamic> readUserDefaults(String key, {required String type}) async =>
    await platform
        .invokeMethod<dynamic>('read_user_defaults', {'key': key, 'type': type});

Future<String?> getString(String key) async =>
    await readUserDefaults(key, type: 'string') as String?;

Future<bool?> getBool(String key) async =>
    await readUserDefaults(key, type: 'bool') as bool?;

Future<int?> getInt(String key) async =>
    await readUserDefaults(key, type: 'int') as int?;
