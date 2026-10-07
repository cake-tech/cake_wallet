import 'dart:convert';

import 'package:cw_core/cake_hive.dart';
import 'package:hive/hive.dart';

class PayjoinEventStore {
  Box<String>? _box;
  Future<Box<String>>? _opening;

  static const _boxName = 'PayjoinSessionEvents';

  bool get isReady => _box != null && _box!.isOpen;

  /// Concurrent-safe: parallel callers (e.g. an unawaited `initPayjoin`
  /// racing a receive-page `initReceiver`) share one in-flight `openBox`
  /// future instead of issuing duplicate opens; a failed open clears the
  /// in-flight future so the next call retries.
  Future<Box<String>> ensureOpen() async {
    final box = _box;
    if (box != null && box.isOpen) return box;
    final opening = _opening ??= CakeHive.openBox<String>(_boxName);
    try {
      final opened = await opening;
      _box = opened;
      _opening = null;
      return opened;
    } catch (_) {
      _opening = null;
      rethrow;
    }
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
