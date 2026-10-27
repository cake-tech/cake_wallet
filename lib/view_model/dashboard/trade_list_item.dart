import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/view_model/dashboard/action_list_item.dart";

class TradeListItem extends ActionListItem {
  TradeListItem({
    required this.trade,
    required this.appStore,
    required super.key,
  });

  final Trade trade;
  final AppStore appStore;

  BalanceDisplayMode get displayMode => appStore.settingsStore.balanceDisplayMode;

  String get tradeFormattedAmount {
    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }
    return trade.depositAmount.toStringWithSymbol();
  }

  String get tradeFormattedReceiveAmount {
    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }
    return trade.payoutAmount.toStringWithSymbol();
  }

  @override
  DateTime get date => trade.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
