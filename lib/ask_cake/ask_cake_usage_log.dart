import 'dart:convert';
import 'dart:io';

import 'package:cake_wallet/ask_cake/ask_cake_router.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A tester's own record of what they asked, what Ask Cake understood and what
/// they did next. It exists to find requests the router gets wrong.
///
/// It is off unless switched on from the hidden test page, stays in a file on
/// this device, and is never sent anywhere by the app: the tester shares the
/// file themselves if they choose to. Addresses and invoices are replaced with
/// a placeholder before a line is written, and a message that looked like a
/// recovery phrase or key is never written at all.
class AskCakeUsageLog {
  AskCakeUsageLog._();

  static const _preference = 'ask_cake_test_log_enabled';
  static const _fileName = 'ask_cake_test_log.jsonl';

  /// Read once at start-up of the chat and changed from the test page.
  static final enabled = ValueNotifier<bool>(false);

  static Future<void> load() async =>
      enabled.value = (await SharedPreferences.getInstance()).getBool(_preference) ?? false;

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await (await SharedPreferences.getInstance()).setBool(_preference, value);
  }

  static Future<File> file() async => File('${(await getApplicationDocumentsDirectory()).path}/$_fileName');

  /// One exchange: the message, how it was routed and what was offered.
  static Future<void> exchange({
    required String message,
    required String route,
    double? confidence,
    String? offered,
    List<String> options = const [],
  }) {
    if (route == 'secret_input') return Future.value();
    return _write({
      'event': 'exchange',
      'message': askCakeMaskAddresses(message),
      'route': _withoutAddresses(route),
      if (confidence != null) 'confidence': double.parse(confidence.toStringAsFixed(3)),
      if (offered != null) 'offered': offered,
      if (options.isNotEmpty) 'options': options,
    });
  }

  /// What the tester did with the reply: pressed its button, picked an option, copied an ID.
  static Future<void> followUp(String kind, String label) => _write({'event': kind, 'label': label});

  static String _withoutAddresses(String route) => route.split(' ').map(askCakeMaskAddresses).join(' ');

  static Future<void> _write(Map<String, dynamic> entry) async {
    if (!enabled.value) return;
    try {
      await (await file()).writeAsString(
          '${jsonEncode({'at': DateTime.now().toUtc().toIso8601String(), ...entry})}\n',
          mode: FileMode.append,
          flush: true);
    } on FileSystemException {
      // A test log must never get in the way of the chat.
    }
  }

  static Future<int> lineCount() async {
    final log = await file();
    return log.existsSync() ? (await log.readAsLines()).length : 0;
  }

  static Future<void> clear() async {
    final log = await file();
    if (log.existsSync()) await log.delete();
  }
}
