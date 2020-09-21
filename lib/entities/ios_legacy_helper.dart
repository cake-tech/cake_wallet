import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const platform =
    const MethodChannel('com.cakewallet.cakewallet/legacy_wallet_migration');

Future<String> readTradeList(
        {@required String key, @required String salt}) async =>
    await platform.invokeMethod('read_trade_list', {'key': key, 'salt': salt});

Future<String> readEncryptedFile(String url,
        {@required String key, @required String salt}) async =>
    await platform.invokeMethod(
        'read_encrypted_file', {'url': url, 'key': key, 'salt': salt});
