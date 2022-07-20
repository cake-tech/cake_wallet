import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';

part'trade_filter_store.g.dart';

class TradeFilterStore = TradeFilterStoreBase with _$TradeFilterStore;

abstract class TradeFilterStoreBase with Store {
  TradeFilterStoreBase(
      {this.displayXMRTO = false,
        this.displayAllTrades = true,
        this.displayChangeNow = false,
        this.displaySideShift = false,
        this.displayMorphToken = false});

  @observable
  bool displayXMRTO;

  @observable
  bool displayAllTrades;

  @observable
  bool displayChangeNow;

  @observable
  bool displaySideShift;

  @observable
  bool displayMorphToken;

  @action
  void toggleDisplayExchange(ExchangeProviderDescription provider) {
    switch (provider) {
      case ExchangeProviderDescription.changeNow:
        displayChangeNow = !displayChangeNow;
        break;
      case ExchangeProviderDescription.sideShift:
        displaySideShift = !displaySideShift;
        break;
      case ExchangeProviderDescription.xmrto:
        displayXMRTO = !displayXMRTO;
        break;
      case ExchangeProviderDescription.morphToken:
        displayMorphToken = !displayMorphToken;
        break;
      case ExchangeProviderDescription.all:
        displayAllTrades = true;
        break;
    }
  }

  List<TradeListItem> filtered({List<TradeListItem> trades, WalletBase wallet}) {
    final _trades =
    trades.where((item) => item.trade.walletId == wallet.id).toList();
    final needToFilter = !displayChangeNow || !displaySideShift || !displayXMRTO || !displayMorphToken;

    return needToFilter
        ? _trades
        .where((item) =>
    (displayXMRTO &&
        item.trade.provider == ExchangeProviderDescription.xmrto) ||
        (displayChangeNow &&
            item.trade.provider ==
                ExchangeProviderDescription.changeNow) ||
        (displaySideShift &&
            item.trade.provider ==
                ExchangeProviderDescription.sideShift) ||
        (displayMorphToken &&
            item.trade.provider ==
                ExchangeProviderDescription.morphToken))
        .toList()
        : _trades;
  }
}