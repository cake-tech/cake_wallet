import 'dart:async';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/settings_store.dart';

part 'trades_store.g.dart';

class TradesStore = TradesStoreBase with _$TradesStore;

abstract class TradesStoreBase with Store {
  TradesStoreBase({required this.tradesSource, required this.settingsStore})
    : trades = <TradeListItem>[] {
    _onTradesChanged =
        tradesSource.watch().listen((_) async => await updateTradeList());
    updateTradeList();
  }

  Box<Trade> tradesSource;
  StreamSubscription<BoxEvent>? _onTradesChanged;
  SettingsStore settingsStore;

  @observable
  List<TradeListItem> trades;

  @observable
  Trade? trade;

  @action
  void setTrade(Trade trade) => this.trade = trade;

  @action
  Future<void> updateTradeList() async => trades =
      tradesSource.values.map((trade) => TradeListItem(
          trade: trade,
          settingsStore: settingsStore)).toList();
}