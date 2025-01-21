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
    this.status
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
  String walletId;

  @HiveField(1)
  String? sender;

  @HiveField(2)
  String? receiver;

  @HiveField(3)
  String? pjUri;

  @HiveField(4)
  String? status;

  bool get isSenderSession => sender != null;
}
