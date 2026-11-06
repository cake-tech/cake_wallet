import 'dart:async';

import 'package:cw_core/db/sqlite.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// SQLite-backed persistence for payjoin sessions (table `PayjoinSession`).
///
/// Replaces the former Hive `PayjoinSessions` box. Rows are keyed by the same
/// `pj_recv_<endpoint>` / `pj_send_<pjUri>` identifiers the box used, so UI
/// session ids are unchanged. [changes] is a process-wide broadcast stream
/// (multiple [PayjoinStorage] instances exist — one per wallet — so the
/// stream is static) that fires after every mutation, replacing the old
/// `box.watch()` reactivity.
class PayjoinStorage {
  static final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  /// Fires after every session insert/update/delete.
  static Stream<void> get changes => _changesController.stream;

  static const String _tableName = 'PayjoinSession';

  static const String _receiverPrefix = 'pj_recv_';
  static const String _senderPrefix = 'pj_send_';

  Database get _db => db!;

  PayjoinSession _fromRow(Map<String, Object?> row) => PayjoinSession(
        walletId: row['walletId'] as String,
        sender: row['sender'] as String?,
        receiver: row['receiver'] as String?,
        pjUri: row['pjUri'] as String?,
        status: row['status'] as String,
        inProgressSince: row['inProgressSince'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row['inProgressSince'] as int),
        rawAmount: row['rawAmount'] as String?,
      )
        ..txId = row['txId'] as String?
        ..error = row['error'] as String?
        ..originalPsbt = row['originalPsbt'] as String?
        ..usedFallback = (row['usedFallback'] as int? ?? 0) != 0
        ..recipientAddress = row['recipientAddress'] as String?;

  Map<String, Object?> _toRow(String sessionId, PayjoinSession session) => {
        'sessionId': sessionId,
        'walletId': session.walletId,
        'sender': session.sender,
        'receiver': session.receiver,
        'pjUri': session.pjUri,
        'status': session.status,
        'inProgressSince': session.inProgressSince?.millisecondsSinceEpoch,
        'txId': session.txId,
        'rawAmount': session.rawAmount,
        'error': session.error,
        'originalPsbt': session.originalPsbt,
        'usedFallback': session.usedFallback ? 1 : 0,
        'recipientAddress': session.recipientAddress,
      };

  Future<void> _upsert(String sessionId, PayjoinSession session) async {
    final row = _toRow(sessionId, session);
    // Update in place when the row exists so its rowid is preserved: the Hive
    // box kept insertion order across updates, and REPLACE would delete and
    // reinsert the row, moving an updated session to the end of the list.
    final updated =
        await _db.update(_tableName, row, where: 'sessionId = ?', whereArgs: [sessionId]);
    if (updated == 0) {
      await _db.insert(_tableName, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    _changesController.add(null);
  }

  /// Loads the session for [sessionId], applies [change], and persists it.
  /// Mirrors the old read-mutate-`session.save()` pattern; safe under the
  /// single-threaded event loop.
  Future<void> _mutate(
    String sessionId,
    void Function(PayjoinSession) change,
  ) async {
    final session = await _getSessionByKey(sessionId);
    if (session == null) return;
    change(session);
    await _upsert(sessionId, session);
  }

  Future<void> insertReceiverSession(
    String receiverId,
    String walletId, {
    String? recipientAddress,
  }) =>
      _upsert(
        "$_receiverPrefix$receiverId",
        PayjoinSession(
          walletId: walletId,
          receiver: receiverId,
        )..recipientAddress = recipientAddress,
      );

  Future<PayjoinSession?> getUnusedActiveReceiverSession(String walletId) async {
    final rows = await _db.query(
      _tableName,
      where: 'walletId = ? AND status = ? AND sender IS NULL',
      whereArgs: [walletId, PayjoinSessionStatus.created.name],
      // Oldest first — mirrors the insertion order the Hive box iterated in.
      orderBy: 'rowid ASC',
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<void> markReceiverSessionComplete(String sessionId, String txId,
      String amount, {bool usedFallback = false}) async {
    final key = "$_receiverPrefix$sessionId";
    final session = (await _getSessionByKey(key))!;
    session
      ..status = PayjoinSessionStatus.success.name
      ..txId = txId
      ..rawAmount = amount
      ..usedFallback = usedFallback;
    await _upsert(key, session);
  }

  Future<void> markReceiverSessionUnrecoverable(String sessionId, String reason) =>
      _mutate("$_receiverPrefix$sessionId", (session) {
        session.status = PayjoinSessionStatus.unrecoverable.name;
        session.error = reason;
      });

  /// Marks the session cancelled by an explicit user action. Clears any
  /// stale error so the UI shows a clean "Cancelled" status.
  Future<void> markReceiverSessionCancelled(String sessionId) =>
      _mutate("$_receiverPrefix$sessionId", (session) {
        session.status = PayjoinSessionStatus.cancelled.name;
        session.error = null;
      });

  Future<void> markReceiverSessionInProgress(String sessionId) =>
      _mutate("$_receiverPrefix$sessionId", (session) {
        session.status = PayjoinSessionStatus.inProgress.name;
        session.inProgressSince ??= DateTime.now();
      });

  Future<void> markReceiverSessionWaiting(String sessionId) =>
      _mutate("$_receiverPrefix$sessionId", (session) {
        session.status = PayjoinSessionStatus.waiting.name;
        session.inProgressSince = DateTime.now();
      });

  Future<void> insertSenderSession(
    String pjUrl,
    String walletId,
    BigInt amount, {
    String? originalPsbt,
    int? networkFeesSatPerVb,
    String? recipientAddress,
  }) =>
      _upsert(
        "$_senderPrefix$pjUrl",
        PayjoinSession(
          walletId: walletId,
          pjUri: pjUrl,
          sender: 'v2',
          status: PayjoinSessionStatus.inProgress.name,
          inProgressSince: DateTime.now(),
          rawAmount: amount.toString(),
        )
          ..originalPsbt = originalPsbt
          ..recipientAddress = recipientAddress,
      );

  Future<void> markSenderSessionFallback(String pjUrl) =>
      _mutate("$_senderPrefix$pjUrl", (session) {
        session.usedFallback = true;
      });

  Future<void> markSenderSessionWaiting(String pjUrl) =>
      _mutate("$_senderPrefix$pjUrl", (session) {
        session.status = PayjoinSessionStatus.waiting.name;
        session.inProgressSince ??= DateTime.now();
      });

  Future<void> markSenderSessionInProgress(String pjUrl) =>
      _mutate("$_senderPrefix$pjUrl", (session) {
        session.status = PayjoinSessionStatus.inProgress.name;
        session.inProgressSince ??= DateTime.now();
      });

  Future<void> markSenderSessionComplete(String pjUrl, String txId,
      {bool usedFallback = false}) async {
    final key = "$_senderPrefix$pjUrl";
    final session = (await _getSessionByKey(key))!;
    session
      ..status = PayjoinSessionStatus.success.name
      ..txId = txId
      ..usedFallback = usedFallback;
    await _upsert(key, session);
  }

  Future<void> markSenderSessionUnrecoverable(String pjUrl, String reason) async {
    final key = "$_senderPrefix$pjUrl";
    final session = await _getSessionByKey(key);
    if (session == null) return;

    // Don't downgrade a session that has already broadcast via fallback.
    // The sender catch handler races with fallbackBroadcast — the session
    // is already marked success+usedFallback=true.
    if (session.usedFallback) return;

    session
      ..status = PayjoinSessionStatus.unrecoverable.name
      ..error = reason;
    await _upsert(key, session);
  }

  /// Marks the session cancelled by an explicit user action. Skips sessions
  /// that already broadcast (or are broadcasting) via fallback.
  Future<void> markSenderSessionCancelled(String pjUrl) async {
    final key = "$_senderPrefix$pjUrl";
    final session = await _getSessionByKey(key);
    if (session == null) return;
    if (session.usedFallback) return;
    if (session.status == PayjoinSessionStatus.success.name) return;

    session
      ..status = PayjoinSessionStatus.cancelled.name
      ..error = null;
    await _upsert(key, session);
  }

  Future<PayjoinSession?> getSenderSession(String pjUrl) =>
      _getSessionByKey("$_senderPrefix$pjUrl");

  Future<PayjoinSession?> getReceiverSession(String receiverId) =>
      _getSessionByKey("$_receiverPrefix$receiverId");

  /// Public single-key lookup (full `pj_recv_*` / `pj_send_*` id).
  Future<PayjoinSession?> getSessionByKey(String key) => _getSessionByKey(key);

  Future<PayjoinSession?> _getSessionByKey(String key) async {
    final rows = await _db.query(
      _tableName,
      where: 'sessionId = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<PayjoinSession?> getSessionByTxId(String txId, {String? walletId}) async {
    final rows = await _rowsForTxId(txId, walletId);
    // Parity with the old linear scan: first matching session wins.
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<List<Map<String, Object?>>> _rowsForTxId(String txId, String? walletId) {
    final where = StringBuffer('txId = ? AND txId != ?');
    final args = <Object?>[txId, ''];
    if (walletId != null) {
      where.write(' AND walletId = ?');
      args.add(walletId);
    }
    return _db.query(_tableName,
        where: where.toString(), whereArgs: args, orderBy: 'rowid ASC');
  }

  /// All sessions with their storage keys (`pj_recv_*` / `pj_send_*`),
  /// replacing the old `box.toMap()`.
  Future<List<MapEntry<String, PayjoinSession>>> readAllWithKeys() async {
    // rowid order matches the old Hive box's insertion order.
    final rows = await _db.query(_tableName, orderBy: 'rowid ASC');
    return rows
        .map((row) => MapEntry(row['sessionId'] as String, _fromRow(row)))
        .toList();
  }

  /// Finds a non-sender session in [walletId] whose [PayjoinSession.recipientAddress]
  /// appears in [addresses]. Used to retroactively associate a broadcast tx
  /// with a receiver session whose worker never reached the
  /// `markReceiverSessionComplete` path (e.g. wallet-switch killed the worker
  /// mid-flight, or replay landed in a terminal FFI state that threw before
  /// the psbt was returned).
  ///
  /// The same script address can back multiple receiver sessions (one per
  /// receive-page visit), so only sessions that can still be pending are
  /// eligible (never a success/cancelled one, never one already tied to a
  /// txId) and the most recent one wins — older stale sessions must never
  /// absorb the outcome of a newer request.
  Future<PayjoinSession?> findReceiverSessionByRecipientAddress(
    String walletId,
    Set<String> addresses,
  ) async {
    if (addresses.isEmpty) {
      return null;
    }
    PayjoinSession? best;
    for (final entry in await readAllWithKeys()) {
      final session = entry.value;
      if (session.walletId != walletId) {
        continue;
      }
      if (session.isSenderSession) {
        continue;
      }
      if (session.txId?.isNotEmpty ?? false) {
        continue;
      }
      if (session.status == PayjoinSessionStatus.success.name) {
        continue;
      }
      if (session.status == PayjoinSessionStatus.cancelled.name) {
        continue;
      }
      // Only sessions with evidence of a submitted original payload are
      // eligible: a plain (non-payjoin) payment to the recipient address
      // must not be claimed as the session's outcome.
      final hasProposalEvidence =
          (session.originalPsbt?.isNotEmpty ?? false) ||
              (BigInt.tryParse(session.rawAmount ?? '') ?? BigInt.zero) >
                  BigInt.zero;
      if (!hasProposalEvidence) {
        continue;
      }
      final recipient = session.recipientAddress;
      if (recipient == null || recipient.isEmpty || !addresses.contains(recipient)) {
        continue;
      }
      final bestSince = best?.inProgressSince;
      final since = session.inProgressSince;
      if (best == null ||
          (since != null && (bestSince == null || since.isAfter(bestSince)))) {
        best = session;
      }
    }
    return best;
  }

  Future<bool> hasActiveReceiverSession(String walletId) async {
    final count = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_tableName '
      'WHERE walletId = ? AND sender IS NULL AND status = ?',
      [walletId, PayjoinSessionStatus.inProgress.name],
    );
    return (count.first['c'] as int? ?? 0) > 0;
  }

  /// Loads the receiver session for [sessionId], applies [change], persists.
  /// Public escape hatch for the multi-field read-modify-write sites that
  /// previously mutated a Hive object and called `session.save()`.
  /// Returns false when the session doesn't exist.
  Future<bool> mutateReceiver(
    String sessionId,
    void Function(PayjoinSession session) change,
  ) async {
    final key = "$_receiverPrefix$sessionId";
    final session = await _getSessionByKey(key);
    if (session == null) return false;
    change(session);
    await _upsert(key, session);
    return true;
  }

  Future<void> storeReceiverPsbt(String sessionId, String psbt) =>
      _mutate("$_receiverPrefix$sessionId", (session) {
        session.originalPsbt = psbt;
      });

  /// Returns [PayjoinSession] for both sender (keyed by pjUri) and receiver
  /// (keyed by endpoint), or null if no match.
  Future<PayjoinSession?> getSessionByEndpoint(String endpoint) async {
    return await _getSessionByKey("$_senderPrefix$endpoint") ??
        await _getSessionByKey("$_receiverPrefix$endpoint");
  }

  /// Include unrecoverable sessions that have a stored fallback PSBT so the
  /// "keep around until fallback broadcast" pattern works — the user can
  /// still see and broadcast the fallback tx even after the session failed.
  Future<List<PayjoinSession>> readAllOpenSessions(String walletId) async {
    final sessions = <PayjoinSession>[];
    for (final entry in await readAllWithKeys()) {
      final session = entry.value;
      if (session.walletId != walletId) continue;
      if (session.status == PayjoinSessionStatus.success.name) continue;
      // Explicit user cancel is terminal — never resume, even with a stored
      // fallback PSBT (the user chose to abandon the payjoin).
      if (session.status == PayjoinSessionStatus.cancelled.name) continue;
      if (session.status == PayjoinSessionStatus.unrecoverable.name) {
        // Keep unrecoverable sessions IF they have a stored fallback PSBT
        // (broadcast not yet done) OR if they haven't used the fallback yet.
        if (!(session.originalPsbt?.isNotEmpty == true && !session.usedFallback)) {
          continue;
        }
      }
      sessions.add(session);
    }
    return sessions;
  }

  Future<List<PayjoinSession>> readAllSessions(String walletId) async {
    final rows = await _db.query(
      _tableName,
      where: 'walletId = ?',
      whereArgs: [walletId],
      orderBy: 'rowid ASC',
    );
    return rows.map(_fromRow).toList();
  }
}
