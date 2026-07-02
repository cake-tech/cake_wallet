import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:payjoin/payjoin.dart' as pj;

class PayjoinSenderPersister extends pj.JsonSenderSessionPersister {
  final Box<String> _box;
  final String _key;

  PayjoinSenderPersister(Box<String> box, String sessionId)
      : _box = box,
        _key = 'send_$sessionId';

  @override
  void save(String event) {
    final raw = _box.get(_key, defaultValue: '[]') as String;
    final events = (jsonDecode(raw) as List).cast<String>();
    events.add(event);
    _box.put(_key, jsonEncode(events));
  }

  @override
  List<String> load() {
    final raw = _box.get(_key);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  @override
  void close() {}
}

class PayjoinReceiverPersister extends pj.JsonReceiverSessionPersister {
  final Box<String> _box;
  final String _key;

  PayjoinReceiverPersister(Box<String> box, String sessionId)
      : _box = box,
        _key = 'recv_$sessionId';

  @override
  void save(String event) {
    final raw = _box.get(_key, defaultValue: '[]') as String;
    final events = (jsonDecode(raw) as List).cast<String>();
    events.add(event);
    _box.put(_key, jsonEncode(events));
  }

  @override
  List<String> load() {
    final raw = _box.get(_key);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  @override
  void close() {}
}
