import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';

class TradeListItem extends ActionListItem {
  TradeListItem({this.trade, this.displayMode});

  final Trade trade;
  final BalanceDisplayMode displayMode;

  String get tradeFormattedAmount {
    return trade.amount != null
        ? displayMode == BalanceDisplayMode.hiddenBalance
          ? '---'
          : trade.amountFormatted()
        : trade.amount;
  }

  @override
  DateTime get date => trade.createdAt;
}
