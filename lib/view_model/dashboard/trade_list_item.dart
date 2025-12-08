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

  String get tradeFormattedAmount => displayMode == BalanceDisplayMode.hiddenBalance
      ? "---"
      : appStore.amountParsingProxy.getCryptoOutputAmount(trade.amountFormatted(), trade.from!);

  String get tradeFormattedReceiveAmount => displayMode == BalanceDisplayMode.hiddenBalance
      ? "---"
      : appStore.amountParsingProxy
          .getCryptoOutputAmount(trade.receiveAmountFormatted(), trade.to!);

  @override
  DateTime get date => trade.createdAt!;
}
