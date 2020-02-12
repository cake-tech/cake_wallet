import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/stores/action_list/trade_list_item.dart';

part 'trade_filter_store.g.dart';

class TradeFilterStore = TradeFilterStoreBase with _$TradeFilterStore;

abstract class TradeFilterStoreBase with Store {
  TradeFilterStoreBase(
      {this.displayXMRTO = true,
      this.displayChangeNow = true,
      this.displayMorphToken = true,
      this.walletStore});

  @observable
  bool displayXMRTO;

  @observable
  bool displayChangeNow;

  @observable
  bool displayMorphToken;

  WalletStore walletStore;

  @action
  void toggleDisplayExchange(ExchangeProviderDescription provider) {
    switch (provider) {
      case ExchangeProviderDescription.changeNow:
        displayChangeNow = !displayChangeNow;
        break;
      case ExchangeProviderDescription.xmrto:
        displayXMRTO = !displayXMRTO;
        break;
      case ExchangeProviderDescription.morphToken:
        displayMorphToken = !displayMorphToken;
        break;
    }
  }

  List<TradeListItem> filtered({List<TradeListItem> trades}) {
    final _trades =
        trades.where((item) => item.trade.walletId == walletStore.id).toList();
    final needToFilter = !displayChangeNow || !displayXMRTO || !displayMorphToken;

    return needToFilter
        ? trades
            .where((item) =>
                (displayXMRTO &&
                    item.trade.provider == ExchangeProviderDescription.xmrto) ||
                (displayChangeNow &&
                    item.trade.provider ==
                        ExchangeProviderDescription.changeNow) ||
                (displayMorphToken &&
                    item.trade.provider ==
                        ExchangeProviderDescription.morphToken))
            .toList()
        : _trades;
  }
}
