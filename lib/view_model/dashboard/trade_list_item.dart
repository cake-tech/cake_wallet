import "package:cake_wallet/entities/balance_display_mode.dart";
import "package:cake_wallet/exchange/trade.dart";
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_trade_record.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_provider_label.dart';
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/view_model/dashboard/action_list_item.dart";

class TradeListItem extends ActionListItem {
  TradeListItem({
    required this.trade,
    required this.appStore,
    required super.key,
  }) {
    if (trade.provider == ExchangeProviderDescription.pegaRoute) {
      try { PegarouteTradeRecord.read(trade); }
      catch (_) { /* Unavailable records cannot authorize sending. */ }
    }
  }

  String? get providerDisplayName => trade.provider == ExchangeProviderDescription.pegaRoute
      ? tradeProviderDisplayName(trade) : null;

  final Trade trade;
  final AppStore appStore;

  BalanceDisplayMode get displayMode => appStore.settingsStore.balanceDisplayMode;

  String get tradeFormattedAmount {
    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }
    final from = trade.from;
    if (from == null) return trade.amountFormatted();
    return appStore.amountParsingProxy.getDisplayCryptoAmount(trade.amountFormatted(), from);
  }

  String get tradeFormattedReceiveAmount {
    if (displayMode == BalanceDisplayMode.hiddenBalance) {
      return '---';
    }
    final to = trade.to;
    if (to == null) return trade.receiveAmountFormatted();
    return appStore.amountParsingProxy.getDisplayCryptoAmount(trade.receiveAmountFormatted(), to);
  }

  @override
  DateTime get date => trade.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
