import 'dart:async';

import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// SQLite-backed event log for payjoin session protocol events (table
/// `PayjoinSessionEvents`, one row per event, ordered by `seq`).
///
/// Replaces the former Hive `PayjoinSessionEvents` box. Reads are served
/// from an in-memory cache seeded once from SQLite because the persister
/// interface (`Json{Sender,Receiver}SessionPersister.save/load`) is
/// synchronous — the same semantics Hive offered (sync memory writes, async
/// durable flush). Appends persist asynchronously; a failed insert is logged
/// but never blocks the protocol (matching Hive's lazy flush behavior).
class PayjoinEventStore {
  static const String _tableName = 'PayjoinSessionEvents';

  final Map<String, List<String>> _cache = {};
  final Map<String, int> _nextSeq = {};
  Future<void>? _opening;
  bool _loaded = false;

  bool get isReady => _loaded;

  /// Idempotent; concurrent callers share one in-flight load instead of
  /// seeding the cache twice for the same rows.
  Future<void> ensureOpen() {
    if (_loaded) return Future.value();
    return _opening ??= _load();
  }

  Future<void> _load() async {
    try {
      final rows = await db!.query(_tableName, orderBy: 'seq');
      for (final row in rows) {
        final key = row['sessionKey'] as String;
        final seq = row['seq'] as int;
        _cache.putIfAbsent(key, () => <String>[]).add(row['event'] as String);
        final next = seq + 1;
        if (next > (_nextSeq[key] ?? 0)) _nextSeq[key] = next;
      }
      _loaded = true;
    } finally {
      // A failed load leaves `_loaded` false so the next caller retries.
      _opening = null;
    }
  }

  List<String> loadReceiver(String sessionId) => load(receiverKey(sessionId));

  List<String> loadSender(String sessionId) => load(senderKey(sessionId));

  static String receiverKey(String sessionId) => 'recv_$sessionId';

  static String senderKey(String sessionId) => 'send_$sessionId';

  /// Appends [event] under [key]. Synchronous cache write, asynchronous
  /// durable insert (never blocks or fails the protocol).
  void append(String key, String event) {
    final events = _cache.putIfAbsent(key, () => <String>[]);
    events.add(event);
    final seq = _nextSeq[key] ?? events.length - 1;
    _nextSeq[key] = seq + 1;

    final database = db;
    if (database == null) {
      // Callers are expected to await `ensureOpen()` first; if the database
      // isn't ready, keep the event in memory rather than failing the protocol.
      printV('[PayjoinEventStore] database not ready, event kept in memory only');
      return;
    }

    unawaited(
      database
          .insert(
        _tableName,
        {
          'sessionKey': key,
          'seq': seq,
          'event': event,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      )
          .catchError((Object e) {
        printV('[PayjoinEventStore] failed to persist event: $e');
        return -1;
      }),
    );
  }

  List<String> load(String key) => List<String>.of(_cache[key] ?? const <String>[]);
}
