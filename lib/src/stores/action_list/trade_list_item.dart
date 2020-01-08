import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_item.dart';

class TradeListItem extends ActionListItem {
  TradeListItem({this.trade});

  final Trade trade;

  @override
  DateTime get date => trade.createdAt;
}
