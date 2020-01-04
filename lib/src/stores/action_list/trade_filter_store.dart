import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/stores/action_list/trade_list_item.dart';

part 'trade_filter_store.g.dart';

class TradeFilterStore = TradeFilterStoreBase with _$TradeFilterStore;

abstract class TradeFilterStoreBase with Store {
  @observable
  bool displayXMRTO;

  @observable
  bool displayChangeNow;

  WalletStore walletStore;

  TradeFilterStoreBase(
      {this.displayXMRTO = true,
      this.displayChangeNow = true,
      this.walletStore});

  @action
  void toggleDisplayExchange(ExchangeProviderDescription provider) {
    switch (provider) {
      case ExchangeProviderDescription.changeNow:
        displayChangeNow = !displayChangeNow;
        break;
      case ExchangeProviderDescription.xmrto:
        displayXMRTO = !displayXMRTO;
        break;
    }
  }

  List<TradeListItem> filtered({List<TradeListItem> trades}) {
    List<TradeListItem> _trades =
        trades.where((item) => item.trade.walletId == walletStore.id).toList();

    final needToFilter = !displayChangeNow || !displayXMRTO;

    return needToFilter
        ? trades
            .where((item) =>
                (displayXMRTO &&
                    item.trade.provider == ExchangeProviderDescription.xmrto) ||
                (displayChangeNow &&
                    item.trade.provider ==
                        ExchangeProviderDescription.changeNow))
            .toList()
        : _trades;
  }
}
