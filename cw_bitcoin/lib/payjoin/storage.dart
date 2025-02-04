import 'package:cw_core/payjoin_session.dart';
import 'package:hive/hive.dart';
import 'package:payjoin_flutter/receive.dart';
import 'package:payjoin_flutter/send.dart';

class PayjoinStorage {
  PayjoinStorage(this._payjoinSessionSources);

  final Box<PayjoinSession> _payjoinSessionSources;

  static const String _receiverPrefix = 'pj_recv_';
  static const String _senderPrefix = 'pj_send_';

  Future<void> insertReceiverSession(
    Receiver receiver,
    String walletId,
  ) =>
      _payjoinSessionSources.put(
        "$_receiverPrefix${receiver.id()}",
        PayjoinSession(
          walletId: walletId,
          receiver: receiver.toJson(),
        ),
      );

  Future<void> markReceiverSessionComplete(String sessionId) async {
    final session = _payjoinSessionSources.get("$_receiverPrefix${sessionId}")!;

    session.status = PayjoinSessionStatus.success.name;
    await session.save();
  }

  Future<void> markReceiverSessionUnrecoverable(String sessionId) async {
    final session = _payjoinSessionSources.get("$_receiverPrefix${sessionId}")!;

    session.status = PayjoinSessionStatus.unrecoverable.name;
    await session.save();
  }

  Future<void> markReceiverSessionInProgress(String sessionId) async {
    final session = _payjoinSessionSources.get("$_receiverPrefix${sessionId}")!;

    session.status = PayjoinSessionStatus.inProgress.name;
    session.inProgressSince = DateTime.now();
    await session.save();
  }

  Future<void> insertSenderSession(
    Sender sender,
    String pjUrl,
    String walletId,
  ) =>
      _payjoinSessionSources.put(
        "$_senderPrefix$pjUrl",
        PayjoinSession(
          walletId: walletId,
          pjUri: pjUrl,
          sender: sender.toJson(),
          status: PayjoinSessionStatus.inProgress.name,
          inProgressSince: DateTime.now(),
        ),
      );

  Future<void> markSenderSessionComplete(String pjUrl) async {
    final session = _payjoinSessionSources.get("$_senderPrefix$pjUrl")!;

    session.status = PayjoinSessionStatus.success.name;
    await session.save();
  }

  Future<void> markSenderSessionUnrecoverable(String pjUrl) async {
    final session = _payjoinSessionSources.get("$_senderPrefix$pjUrl")!;

    session.status = PayjoinSessionStatus.unrecoverable.name;
    await session.save();
  }

  List<PayjoinSession> readAllOpenSessions(String walletId) =>
      _payjoinSessionSources.values
          .where((session) =>
              session.walletId == walletId &&
              session.status != PayjoinSessionStatus.success.name &&
              session.status != PayjoinSessionStatus.unrecoverable.name)
          .toList();

  List<PayjoinSession> readAllInProgressOrFinishedSessions(String walletId) =>
      _payjoinSessionSources.values
          .where((session) =>
              session.walletId == walletId &&
              [
                PayjoinSessionStatus.inProgress.name,
                PayjoinSessionStatus.success.name,
                PayjoinSessionStatus.unrecoverable.name
              ].contains(session.status))
          .toList();
}
