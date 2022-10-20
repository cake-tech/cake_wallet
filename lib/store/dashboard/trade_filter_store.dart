import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';

part'trade_filter_store.g.dart';

class TradeFilterStore = TradeFilterStoreBase with _$TradeFilterStore;

abstract class TradeFilterStoreBase with Store {
  TradeFilterStoreBase(
      {this.displayXMRTO = true,
        this.displayChangeNow = true,
        this.displayMorphToken = true,
        this.displaySimpleSwap = true,
        });

  @observable
  bool displayXMRTO;

  @observable
  bool displayChangeNow;

  @observable
  bool displayMorphToken;

  @observable
  bool displaySimpleSwap;

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
      case ExchangeProviderDescription.simpleSwap:
        displaySimpleSwap = !displaySimpleSwap;
        break;
    }
  }

  List<TradeListItem> filtered({required List<TradeListItem> trades, required WalletBase wallet}) {
    final _trades =
    trades.where((item) => item.trade.walletId == wallet.id).toList();
    final needToFilter = !displayChangeNow || !displayXMRTO || !displayMorphToken || !displaySimpleSwap;

    return needToFilter
        ? _trades
        .where((item) =>
    (displayXMRTO &&
        item.trade.provider == ExchangeProviderDescription.xmrto) ||
        (displayChangeNow &&
            item.trade.provider ==
                ExchangeProviderDescription.changeNow) ||
        (displayMorphToken &&
            item.trade.provider ==
                ExchangeProviderDescription.morphToken)
        ||(displaySimpleSwap &&
            item.trade.provider ==
                ExchangeProviderDescription.simpleSwap))
        .toList()
        : _trades;
  }
}