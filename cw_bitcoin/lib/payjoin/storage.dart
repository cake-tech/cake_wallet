import 'package:cw_core/payjoin_session.dart';
import 'package:hive/hive.dart';

class PayjoinStorage {
  PayjoinStorage(this._payjoinSessionSources);

  final Box<PayjoinSession> _payjoinSessionSources;

  static const String _receiverPrefix = 'pj_recv_';
  static const String _senderPrefix = 'pj_send_';

  Future<void> insertReceiverSession(
    String receiverId,
    String walletId, {
    String? recipientAddress,
  }) =>
      _payjoinSessionSources.put(
        "$_receiverPrefix$receiverId",
        PayjoinSession(
          walletId: walletId,
          receiver: receiverId,
        )..recipientAddress = recipientAddress,
      );

  PayjoinSession? getUnusedActiveReceiverSession(String walletId) => _payjoinSessionSources.values
      .where((session) =>
          session.walletId == walletId &&
          session.status == PayjoinSessionStatus.created.name &&
          !session.isSenderSession)
      .firstOrNull;

  Future<void> markReceiverSessionComplete(String sessionId, String txId, String amount, {bool usedFallback = false}) async {
    final session = _payjoinSessionSources.get("$_receiverPrefix${sessionId}")!;

    session.status = PayjoinSessionStatus.success.name;
    session.txId = txId;
    session.rawAmount = amount;
    session.usedFallback = usedFallback;
    await session.save();
  }

  Future<void> markReceiverSessionUnrecoverable(String sessionId, String reason) async {
    final session = _payjoinSessionSources.get("$_receiverPrefix${sessionId}");
    if (session == null) return;

    session.status = PayjoinSessionStatus.unrecoverable.name;
    session.error = reason;
    await session.save();
  }

  Future<void> markReceiverSessionInProgress(String sessionId) async {
    final session = _payjoinSessionSources.get("$_receiverPrefix${sessionId}");
    if (session == null) return;

    session.status = PayjoinSessionStatus.inProgress.name;
    session.inProgressSince ??= DateTime.now();
    await session.save();
  }

  Future<void> markReceiverSessionWaiting(String sessionId) async {
    final session = _payjoinSessionSources.get("$_receiverPrefix${sessionId}");
    if (session == null) return;

    session.status = PayjoinSessionStatus.waiting.name;
    session.inProgressSince = DateTime.now();
    await session.save();
  }

  Future<void> insertSenderSession(
    String pjUrl,
    String walletId,
    BigInt amount, {
    String? originalPsbt,
    int? networkFeesSatPerVb,
    String? recipientAddress,
  }) =>
      _payjoinSessionSources.put(
        "$_senderPrefix$pjUrl",
        PayjoinSession(
          walletId: walletId,
          pjUri: pjUrl,
          sender: 'v2',
          status: PayjoinSessionStatus.inProgress.name,
          inProgressSince: DateTime.now(),
          rawAmount: amount.toString(),
        )..originalPsbt = originalPsbt..recipientAddress = recipientAddress,
      );

  Future<void> markSenderSessionFallback(String pjUrl) async {
    final session = _payjoinSessionSources.get("$_senderPrefix$pjUrl");
    if (session == null) return;

    session.usedFallback = true;
    await session.save();
  }

  Future<void> markSenderSessionWaiting(String pjUrl) async {
    final session = _payjoinSessionSources.get("$_senderPrefix$pjUrl");
    if (session == null) return;

    session.status = PayjoinSessionStatus.waiting.name;
    session.inProgressSince ??= DateTime.now();
    await session.save();
  }

  Future<void> markSenderSessionInProgress(String pjUrl) async {
    final session = _payjoinSessionSources.get("$_senderPrefix$pjUrl");
    if (session == null) return;

    session.status = PayjoinSessionStatus.inProgress.name;
    session.inProgressSince ??= DateTime.now();
    await session.save();
  }

  Future<void> markSenderSessionComplete(String pjUrl, String txId, {bool usedFallback = false}) async {
    final session = _payjoinSessionSources.get("$_senderPrefix$pjUrl")!;

    session.status = PayjoinSessionStatus.success.name;
    session.txId = txId;
    session.usedFallback = usedFallback;
    await session.save();
  }

  Future<void> markSenderSessionUnrecoverable(String pjUrl, String reason) async {
    final session = _payjoinSessionSources.get("$_senderPrefix$pjUrl");
    if (session == null) return;

    // Don't downgrade a session that has already broadcast via fallback.
    // The sender catch handler races with fallbackBroadcast — the session
    // is already marked success+usedFallback=true.
    if (session.usedFallback) return;

    session.status = PayjoinSessionStatus.unrecoverable.name;
    session.error = reason;
    await session.save();
  }

  PayjoinSession? getSenderSession(String pjUrl) =>
      _payjoinSessionSources.get("$_senderPrefix$pjUrl");

  PayjoinSession? getReceiverSession(String receiverId) =>
      _payjoinSessionSources.get("$_receiverPrefix$receiverId");

  PayjoinSession? getSessionByTxId(String txId, {String? walletId}) {
    for (final session in _payjoinSessionSources.values) {
      if (session.txId == txId &&
          (session.txId?.isNotEmpty ?? false) &&
          (walletId == null || session.walletId == walletId)) {
        return session;
      }
    }
    return null;
  }

  /// Finds a non-sender session in [walletId] whose [PayjoinSession.recipientAddress]
  /// appears in [addresses]. Used to retroactively associate a broadcast tx
  /// with a receiver session whose worker never reached the
  /// `markReceiverSessionComplete` path (e.g. wallet-switch killed the worker
  /// mid-flight, or replay landed in a terminal FFI state that threw before
  /// the psbt was returned).
  PayjoinSession? findReceiverSessionByRecipientAddress(
    String walletId,
    Set<String> addresses,
  ) {
    if (addresses.isEmpty) return null;
    for (final session in _payjoinSessionSources.values) {
      if (session.walletId != walletId) continue;
      if (session.isSenderSession) continue;
      final recipient = session.recipientAddress;
      if (recipient != null && recipient.isNotEmpty && addresses.contains(recipient)) {
        return session;
      }
    }
    return null;
  }

  bool hasActiveReceiverSession(String walletId) => _payjoinSessionSources.values.any((s) =>
      s.walletId == walletId &&
      !s.isSenderSession &&
      s.status == PayjoinSessionStatus.inProgress.name);

  Future<void> storeReceiverPsbt(String sessionId, String psbt) async {
    final session = _payjoinSessionSources.get("$_receiverPrefix$sessionId");
    if (session == null) return;
    session.originalPsbt = psbt;
    await session.save();
  }

  /// Returns [PayjoinSession] for both sender (keyed by pjUri) and receiver
  /// (keyed by endpoint), or null if no match.
  PayjoinSession? getSessionByEndpoint(String endpoint) =>
      _payjoinSessionSources.get("$_senderPrefix$endpoint") ??
      _payjoinSessionSources.get("$_receiverPrefix$endpoint");

  /// Include unrecoverable sessions that have a stored fallback PSBT so the
  /// "keep around until fallback broadcast" pattern works — the user can
  /// still see and broadcast the fallback tx even after the session failed.
  List<PayjoinSession> readAllOpenSessions(String walletId) => _payjoinSessionSources.values
      .where((session) {
    if (session.walletId != walletId) return false;
    if (session.status == PayjoinSessionStatus.success.name) return false;
    if (session.status == PayjoinSessionStatus.unrecoverable.name) {
      // Keep unrecoverable sessions IF they have a stored fallback PSBT
      // (broadcast not yet done) OR if they haven't used the fallback yet.
      return (session.originalPsbt?.isNotEmpty == true && !session.usedFallback);
    }
    return true;
  }).toList();

  List<PayjoinSession> readAllSessions(String walletId) => _payjoinSessionSources.values
      .where((session) => session.walletId == walletId)
      .toList();
}
