import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'payjoin_session.g.dart';

@HiveType(typeId: PAYJOIN_SESSION_TYPE_ID)
class PayjoinSession extends HiveObject {
  PayjoinSession({
    required this.walletId,
    this.receiver,
    this.sender,
    this.pjUri,
    this.status = "created",
    this.inProgressSince
  }) {
    if (receiver == null) {
      assert(sender != null);
      assert(pjUri != null);
    } else {
      assert(receiver != null);
    }
  }

  static const typeId = PAYJOIN_SESSION_TYPE_ID;
  static const boxName = 'PayjoinSessions';

  @HiveField(0)
  final String walletId;

  @HiveField(1)
  final String? sender;

  @HiveField(2)
  final String? receiver;

  @HiveField(3)
  final String? pjUri;

  @HiveField(4)
  String status;

  @HiveField(5)
  DateTime? inProgressSince;

  bool get isSenderSession => sender != null;
}

enum PayjoinSessionStatus {
  created,
  inProgress,
  success,
  unrecoverable,
}
