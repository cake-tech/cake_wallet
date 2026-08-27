import 'package:cw_core/history_source.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/action_list_item.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import "package:cake_wallet/exchange/trade.dart";
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';

part 'trade_filter_store.g.dart';

class TradeFilterStore = TradeFilterStoreBase with _$TradeFilterStore;

abstract class TradeFilterStoreBase with Store implements HistoryFilters {
  TradeFilterStoreBase(this._appStore)
      : displayXMRTO = true,
        displayChangeNow = true,
        displaySideShift = true,
        displayMorphToken = true,
        displaySimpleSwap = true,
        displayTrocador = true,
        displayExolix = true,
        displayChainflip = true,
        displayThorChain = true,
        displayLetsExchange = true,
        displayStealthEx = true,
        displayXOSwap = true,
        displaySwapTrade = true,
        displaySwapXyz = true,
        displayNearIntents = true;

  final AppStore _appStore;

  @observable
  bool displayXMRTO;

  @observable
  bool displayChangeNow;

  @observable
  bool displaySideShift;

  @observable
  bool displayMorphToken;

  @observable
  bool displaySimpleSwap;

  @observable
  bool displayTrocador;

  @observable
  bool displayExolix;

  @observable
  bool displayChainflip;

  @observable
  bool displayThorChain;

  @observable
  bool displayLetsExchange;

  @observable
  bool displayStealthEx;

  @observable
  bool displayXOSwap;

  @observable
  bool displaySwapTrade;

  @observable
  bool displaySwapXyz;
  @observable
  bool displayNearIntents;

  @computed
  int get enabledProvidersCount => [
        displayChangeNow,
        displaySideShift,
        displaySimpleSwap,
        displayTrocador,
        displayExolix,
        displayChainflip,
        displayThorChain,
        displayLetsExchange,
        displayStealthEx,
        displayXOSwap,
        displaySwapTrade,
        displaySwapXyz,
        displayNearIntents
      ].where((item) => item).length;

  @computed
  bool get displayAllTrades =>
      displayChangeNow &&
      displaySideShift &&
      displaySimpleSwap &&
      displayTrocador &&
      displayExolix &&
      displayChainflip &&
      displayThorChain &&
      displayLetsExchange &&
      displayStealthEx &&
      displayXOSwap &&
      displaySwapTrade &&
      displaySwapXyz &&
      displayNearIntents;

  @action
  void toggleDisplayExchange(ExchangeProviderDescription provider) {
    switch (provider) {
      case ExchangeProviderDescription.changeNow:
        displayChangeNow = !displayChangeNow;
        break;
      case ExchangeProviderDescription.sideShift:
        displaySideShift = !displaySideShift;
        break;
      case ExchangeProviderDescription.simpleSwap:
        displaySimpleSwap = !displaySimpleSwap;
        break;
      case ExchangeProviderDescription.xmrto:
        displayXMRTO = !displayXMRTO;
        break;
      case ExchangeProviderDescription.morphToken:
        displayMorphToken = !displayMorphToken;
        break;
      case ExchangeProviderDescription.trocador:
        displayTrocador = !displayTrocador;
        break;
      case ExchangeProviderDescription.exolix:
        displayExolix = !displayExolix;
        break;
      case ExchangeProviderDescription.chainflip:
        displayChainflip = !displayChainflip;
        break;
      case ExchangeProviderDescription.thorChain:
        displayThorChain = !displayThorChain;
        break;
      case ExchangeProviderDescription.letsExchange:
        displayLetsExchange = !displayLetsExchange;
        break;
      case ExchangeProviderDescription.stealthEx:
        displayStealthEx = !displayStealthEx;
        break;
      case ExchangeProviderDescription.xoSwap:
        displayXOSwap = !displayXOSwap;
        break;
      case ExchangeProviderDescription.swapTrade:
        displaySwapTrade = !displaySwapTrade;
        break;
      case ExchangeProviderDescription.swapsXyz:
        displaySwapXyz = !displaySwapXyz;
        break;
      case ExchangeProviderDescription.nearIntents:
        displayNearIntents = !displayNearIntents;
        break;
      case ExchangeProviderDescription.all:
        if (displayAllTrades) {
          displayChangeNow = false;
          displaySideShift = false;
          displayXMRTO = false;
          displayMorphToken = false;
          displaySimpleSwap = false;
          displayTrocador = false;
          displayExolix = false;
          displayChainflip = false;
          displayThorChain = false;
          displayLetsExchange = false;
          displayStealthEx = false;
          displayXOSwap = false;
          displaySwapTrade = false;
          displaySwapXyz = false;
          displayNearIntents = false;
        } else {
          displayChangeNow = true;
          displaySideShift = true;
          displayXMRTO = true;
          displayMorphToken = true;
          displaySimpleSwap = true;
          displayTrocador = true;
          displayExolix = true;
          displayChainflip = true;
          displayThorChain = true;
          displayLetsExchange = true;
          displayStealthEx = true;
          displayXOSwap = true;
          displaySwapTrade = true;
          displaySwapXyz = true;
          displayNearIntents = true;
        }
        break;
    }
  }

  /// Whether one trade passes the wallet, account and provider filters.
  @override
  bool relevant(HistoryListItem item) {
    final wallet = _appStore.wallet;

    if (item is! Trade || wallet == null) {
      return false;
    }

    final isSameChain = item.chainId != null ? item.chainId == wallet.chainId : true;

    if (item.walletId != wallet.id || !isTradeInAccount(item, wallet) || !isSameChain) {
      return false;
    }

    return displayAllTrades || _displaysProvider(item.provider);
  }


  bool _displaysProvider(ExchangeProviderDescription provider) =>
      (displayXMRTO && provider == ExchangeProviderDescription.xmrto) ||
      (displaySideShift && provider == ExchangeProviderDescription.sideShift) ||
      (displayChangeNow && provider == ExchangeProviderDescription.changeNow) ||
      (displayMorphToken && provider == ExchangeProviderDescription.morphToken) ||
      (displaySimpleSwap && provider == ExchangeProviderDescription.simpleSwap) ||
      (displayTrocador && provider == ExchangeProviderDescription.trocador) ||
      (displayExolix && provider == ExchangeProviderDescription.exolix) ||
      (displayChainflip && provider == ExchangeProviderDescription.chainflip) ||
      (displayThorChain && provider == ExchangeProviderDescription.thorChain);

  List<Trade> filtered({required List<Trade> trades}) => trades.where(relevant).toList();

  bool isTradeInAccount(Trade item, WalletBase wallet) =>
      item.fromWalletAddress == null
          ? true
          : wallet.walletAddresses.containsAddress(item.fromWalletAddress!);
}
