import 'package:cw_core/payjoin_session.dart';
import 'package:hive/hive.dart';
import 'package:payjoin_flutter/receive.dart';

class PayjoinStorage {
  PayjoinStorage({required Box<PayjoinSession> payjoinSessionSources})
      : _payjoinSessionSources = payjoinSessionSources;
  final Box<PayjoinSession> _payjoinSessionSources;

  static const String receiverPrefix = 'pj_recv_';
  static const String senderPrefix = 'pj_send_';

  Future<void> insertReceiverSession(
    Receiver receiver,
    String walletId,
  ) async {
    final receiverSession =
        PayjoinSession(walletId: walletId, receiver: receiver.toJson());

    await _payjoinSessionSources.put(
        "$receiverPrefix${receiver.id()}", receiverSession);
  }

// Future<(RecvSession?, Err?)> readReceiverSession(String sessionId) async {
//   try {
//     final (jsn, err) =
//     await _hiveStorage.getValue(receiverPrefix + sessionId);
//     if (err != null) throw err;
//     final obj = jsonDecode(jsn!) as Map<String, dynamic>;
//     final session = RecvSession.fromJson(obj);
//     return (session, null);
//   } catch (e) {
//     return (
//     null,
//     Err(
//       e.toString(),
//       expected: e.toString() == 'No Receiver with id $sessionId',
//     )
//     );
//   }
// }

  Future<void> markReceiverSessionComplete(String sessionId) async {
    final session =
        await _payjoinSessionSources.get("$receiverPrefix${sessionId}")!;

    session.status = "success";
    await session.save();
  }

  Future<void> markReceiverSessionUnrecoverable(String sessionId) async {
    final session =
        await _payjoinSessionSources.get("$receiverPrefix${sessionId}")!;

    session.status = "unrecoverable";
    await session.save();
  }

// Future<(List<RecvSession>, Err?)> readAllReceivers() async {
//   //deleteAllSessions();
//   try {
//     final (allData, err) = await _hiveStorage.getAll();
//     if (err != null) return (List<RecvSession>.empty(), err);
//
//     final List<RecvSession> receivers = [];
//     allData!.forEach((key, value) {
//       if (key.startsWith(receiverPrefix)) {
//         try {
//           final obj = jsonDecode(value) as Map<String, dynamic>;
//           receivers.add(RecvSession.fromJson(obj));
//         } catch (e) {
//           // Skip invalid entries
//           debugPrint('Error: $e');
//         }
//       }
//     });
//     return (receivers, null);
//   } catch (e) {
//     return (List<RecvSession>.empty(), Err(e.toString()));
//   }
// }
//
// Future<Err?> insertSenderSession(
//     Sender sender,
//     String pjUrl,
//     String walletId,
//     bool isTestnet,
//     ) async {
//   try {
//     final sendSession = SendSession(
//       isTestnet,
//       sender,
//       walletId,
//       pjUrl,
//       PayjoinSessionStatus.pending,
//     );
//
//     await _hiveStorage.saveValue(
//       key: senderPrefix + pjUrl,
//       value: jsonEncode(sendSession.toJson()),
//     );
//     return null;
//   } catch (e) {
//     return Err(e.toString());
//   }
// }
//
// Future<(SendSession?, Err?)> readSenderSession(String pjUrl) async {
//   try {
//     final (jsn, err) = await _hiveStorage.getValue(senderPrefix + pjUrl);
//     if (err != null) throw err;
//     final obj = jsonDecode(jsn!) as Map<String, dynamic>;
//     final session = SendSession.fromJson(obj);
//     return (session, null);
//   } catch (e) {
//     return (
//     null,
//     Err(
//       e.toString(),
//       expected: e.toString() == 'No Sender with id $pjUrl',
//     )
//     );
//   }
// }
//
// Future<Err?> markSenderSessionComplete(String pjUrl) async {
//   try {
//     final (session, err) = await readSenderSession(pjUrl);
//     if (err != null) return err;
//
//     final updatedSession = SendSession(
//       session!.isTestnet,
//       session.sender,
//       session.walletId,
//       session.pjUri,
//       PayjoinSessionStatus.success,
//     );
//
//     await _hiveStorage.saveValue(
//       key: senderPrefix + pjUrl,
//       value: jsonEncode(updatedSession.toJson()),
//     );
//     return null;
//   } catch (e) {
//     return Err(e.toString());
//   }
// }
//
// Future<Err?> markSenderSessionUnrecoverable(String pjUri) async {
//   try {
//     final (session, err) = await readSenderSession(pjUri);
//     if (err != null) return err;
//
//     final updatedSession = SendSession(
//       session!.isTestnet,
//       session.sender,
//       session.walletId,
//       session.pjUri,
//       PayjoinSessionStatus.unrecoverable,
//     );
//
//     await _hiveStorage.saveValue(
//       key: senderPrefix + pjUri,
//       value: jsonEncode(updatedSession.toJson()),
//     );
//     return null;
//   } catch (e) {
//     return Err(e.toString());
//   }
// }
//
// Future<(List<SendSession>, Err?)> readAllSenders() async {
//   try {
//     final (allData, err) = await _hiveStorage.getAll();
//     if (err != null) return (List<SendSession>.empty(), err);
//
//     final List<SendSession> senders = [];
//     allData!.forEach((key, value) {
//       if (key.startsWith(senderPrefix)) {
//         try {
//           final obj = jsonDecode(value) as Map<String, dynamic>;
//           senders.add(SendSession.fromJson(obj));
//         } catch (e) {
//           // Skip invalid entries
//           debugPrint('Error: $e');
//         }
//       }
//     });
//     return (senders, null);
//   } catch (e) {
//     return (List<SendSession>.empty(), Err(e.toString()));
//   }
// }
}
