import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cw_core/payjoin_session.dart';

class PayjoinTransactionListItem extends ActionListItem {
  PayjoinTransactionListItem({required this.session, required super.key});

  final PayjoinSession session;

  @override
  DateTime get date => session.inProgressSince!;
}
