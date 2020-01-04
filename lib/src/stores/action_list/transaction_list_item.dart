import 'package:cake_wallet/src/domain/common/transaction_info.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_item.dart';

class TransactionListItem extends ActionListItem {
  final TransactionInfo transaction;

  DateTime get date => transaction.date;

  TransactionListItem({this.transaction});
}