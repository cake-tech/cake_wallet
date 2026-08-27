import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:mobx/mobx.dart';

part 'trades_store.g.dart';

class TradesStore = TradesStoreBase with _$TradesStore;

abstract class TradesStoreBase with Store {
  TradesStoreBase({required this.appStore}) : trades = <Trade>[] {
    Trade.onChanged.stream.listen((_) => updateTradeList());
    updateTradeList();
  }

  AppStore appStore;

  @observable
  List<Trade> trades;

  @observable
  Trade? trade;

  @action
  void setTrade(Trade trade) => this.trade = trade;

  @action
  Future<void> updateTradeList() async {
    try {
      final allTrades = await Trade.getAll();
      runInAction(() {
        trades = allTrades;
      });
    } catch (_) {}
  }
}
