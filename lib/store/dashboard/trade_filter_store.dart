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
  Observable<bool> displaySimpleSwap = Observable(true);

  @action
  void toggleDisplayExchange(ExchangeProviderDescription provider) {
    switch (provider) {
      case ExchangeProviderDescription.changeNow:
        displayAllTrades.value = false;
        displayChangeNow.value = !displayChangeNow.value;
        if (displayChangeNow.value && displaySideShift.value && displaySimpleSwap.value) {
          displayAllTrades.value = true;
        }
        break;
      case ExchangeProviderDescription.sideShift:
        displayAllTrades.value = false;
        displaySideShift.value = !displaySideShift.value;
        if (displayChangeNow.value && displaySideShift.value && displaySimpleSwap.value) {
          displayAllTrades.value = true;
        }
        break;
      case ExchangeProviderDescription.simpleSwap:
        displayAllTrades.value = false;
        displaySimpleSwap.value = !displaySimpleSwap.value;
        if (displayChangeNow.value && displaySideShift.value && displaySimpleSwap.value) {
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
          displaySimpleSwap.value = true;
        }
        if (!displayAllTrades.value) {
          displayChangeNow.value = false;
          displaySideShift.value = false;
          displayXMRTO.value = false;
          displayMorphToken.value = false;
          displaySimpleSwap.value = false;
        }
        break;
    }
  }

  List<TradeListItem> filtered({required List<TradeListItem> trades, required WalletBase wallet}) {
    final _trades =
    trades.where((item) => item.trade.walletId == wallet.id).toList();
    final needToFilter = !displayChangeNow.value || !displaySideShift.value
        || !displayXMRTO.value || !displayMorphToken.value
        || !displaySimpleSwap.value;

    return needToFilter
        ? _trades
        .where((item) =>
    (displayXMRTO.value &&
        item.trade.provider == ExchangeProviderDescription.xmrto) ||
        (displayChangeNow.value &&
            item.trade.provider ==
                ExchangeProviderDescription.changeNow) ||
        (displayMorphToken.value &&
            item.trade.provider ==
                ExchangeProviderDescription.morphToken)
        ||(displaySimpleSwap.value &&
            item.trade.provider ==
                ExchangeProviderDescription.simpleSwap))
        .toList()
        : _trades;
  }
}