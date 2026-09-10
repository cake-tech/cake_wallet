import "package:cake_wallet/generated/i18n.dart";
import "package:cw_core/action_list_item.dart";
import "package:cw_core/payjoin_session.dart";
import "package:cw_core/transaction_info.dart";

class PayjoinTransactionListItem with HistoryListItem {
  PayjoinTransactionListItem({
    required this.sessionId,
    required this.session,
    this.transaction,
  });

  final String sessionId;
  final PayjoinSession session;
  final TransactionInfo? transaction;

  @override
  String get id => sessionId;

  @override
  DateTime get date => session.inProgressSince!;

  String get status {
    switch (session.status) {
      case "success":
        if (transaction?.isPending == false) {
          return S.current.successful;
        }
        return S.current.payjoin_request_awaiting_tx;
      case "inProgress":
        return S.current.payjoin_request_in_progress;
      case "unrecoverable":
        return S.current.error;
      default:
        return session.status;
    }
  }
}
