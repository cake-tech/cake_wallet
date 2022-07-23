import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';

part'trade_filter_store.g.dart';

class TradeFilterStore = TradeFilterStoreBase with _$TradeFilterStore;

abstract class TradeFilterStoreBase with Store {
  TradeFilterStoreBase();

  Observable<bool> displayXMRTO = Observable(true);
  Observable<bool> displayAllTrades = Observable(true);
  Observable<bool> displayChangeNow = Observable(true);
  Observable<bool> displaySideShift = Observable(true);
  Observable<bool> displayMorphToken = Observable(true);

  @action
  void toggleDisplayExchange(ExchangeProviderDescription provider) {
    switch (provider) {
      case ExchangeProviderDescription.changeNow:
        displayAllTrades.value = false;
        displayChangeNow.value = !displayChangeNow.value;
        if (displayChangeNow.value && displaySideShift.value) {
          displayAllTrades.value = true;
        }
        break;
      case ExchangeProviderDescription.sideShift:
        displayAllTrades.value = false;
        displaySideShift.value = !displaySideShift.value;
        if (displayChangeNow.value && displaySideShift.value) {
          displayAllTrades.value = true;
        }
        break;
      case ExchangeProviderDescription.xmrto:
        displayXMRTO.value = !displayXMRTO.value;
        break;
      case ExchangeProviderDescription.morphToken:
        displayMorphToken.value = !displayMorphToken.value;
        break;
      case ExchangeProviderDescription.all:
        displayAllTrades.value = !displayAllTrades.value;
        if (displayAllTrades.value) {
          displayChangeNow.value = true;
          displaySideShift.value = true;
          displayXMRTO.value = true;
          displayMorphToken.value = true;
        }
        if (!displayAllTrades.value) {
          displayChangeNow.value = false;
          displaySideShift.value = false;
          displayXMRTO.value = false;
          displayMorphToken.value = false;
        }
        break;
    }
  }

  List<TradeListItem> filtered({List<TradeListItem> trades, WalletBase wallet}) {
    final _trades =
    trades.where((item) => item.trade.walletId == wallet.id).toList();
    final needToFilter = !displayChangeNow.value || !displaySideShift.value || !displayXMRTO.value || !displayMorphToken.value;

    return needToFilter
        ? _trades
        .where((item) =>
    (displayXMRTO.value &&
        item.trade.provider == ExchangeProviderDescription.xmrto) ||
        (displayChangeNow.value &&
            item.trade.provider ==
                ExchangeProviderDescription.changeNow) ||
        (displaySideShift.value &&
            item.trade.provider ==
                ExchangeProviderDescription.sideShift) ||
        (displayMorphToken.value &&
            item.trade.provider ==
                ExchangeProviderDescription.morphToken))
        .toList()
        : _trades;
  }
}