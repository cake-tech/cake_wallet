import 'dart:convert';

import 'package:cw_core/cake_hive.dart';
import 'package:hive/hive.dart';

class PayjoinEventStore {
  Box<String>? _box;

  static const _boxName = 'PayjoinSessionEvents';

  Future<Box<String>> ensureOpen() async {
    if (_box == null || !_box!.isOpen) {
      _box = await CakeHive.openBox<String>(_boxName);
    }
    return _box!;
  }

  Box<String> get box => _box!;

  static String _receiverKey(String sessionId) => 'recv_$sessionId';
  static String _senderKey(String sessionId) => 'send_$sessionId';

  List<String> loadReceiver(String sessionId) =>
      _load(_receiverKey(sessionId));

  List<String> loadSender(String sessionId) =>
      _load(_senderKey(sessionId));

  List<String> _load(String key) {
    final raw = box.get(key);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }
}
