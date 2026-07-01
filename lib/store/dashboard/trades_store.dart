import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'trades_store.g.dart';

class TradesStore = TradesStoreBase with _$TradesStore;

abstract class TradesStoreBase with Store {
  TradesStoreBase({required this.appStore}) : trades = <TradeListItem>[] {
    Trade.onChanged.stream.listen((_) => updateTradeList());
    updateTradeList();
  }

  AppStore appStore;

  @observable
  List<TradeListItem> trades;

  @observable
  Trade? trade;

  @action
  void setTrade(Trade trade) => this.trade = trade;

  @action
  Future<void> updateTradeList() async {
    try {
      final allTrades = await Trade.getAll();
      runInAction(() {
        trades = allTrades
            .map((trade) => TradeListItem(
                  trade: trade,
                  appStore: appStore,
                  key: ValueKey('trade_list_item_${trade.id}_key'),
                ))
            .toList();
      });
    } catch (_) {}
  }
}
