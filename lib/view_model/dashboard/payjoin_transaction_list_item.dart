import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/action_list_item.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/transaction_info.dart';

/// The one history row that stays a wrapper: a payjoin needs its box key (the
/// session doesn't hold its own id) and the transaction the merge stitches in.
class PayjoinTransactionListItem with ActionListItem {
  PayjoinTransactionListItem({required this.sessionId, required this.session});

  final String sessionId;
  final PayjoinSession session;
  TransactionInfo? transaction;

  /// The txid once broadcast, so this row collides with — and by precedence
  /// replaces — the plain transaction row for the same transaction. Before
  /// broadcast it stands on its own.
  @override
  String get id => session.txId ?? sessionId;

  @override
  DateTime get date => session.inProgressSince!;

  String get status {
    switch (session.status) {
      case 'success':
        if (transaction?.isPending == false) return S.current.successful;
        return S.current.payjoin_request_awaiting_tx;
      case 'inProgress':
        return S.current.payjoin_request_in_progress;
      case 'unrecoverable':
        return S.current.error;
      default:
        return session.status;
    }
  }
}
