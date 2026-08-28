import 'package:collection/collection.dart';
import 'package:cw_core/history_source.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/action_list_item.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import "package:cake_wallet/exchange/trade.dart";
import 'package:cw_core/wallet_base.dart';

class TradeFilterStore extends HistoryFilters {
  TradeFilterStore(this._appStore)
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

  bool displayXMRTO;

  bool displayChangeNow;

  bool displaySideShift;

  bool displayMorphToken;

  bool displaySimpleSwap;

  bool displayTrocador;

  bool displayExolix;

  bool displayChainflip;

  bool displayThorChain;

  bool displayLetsExchange;

  bool displayStealthEx;

  bool displayXOSwap;

  bool displaySwapTrade;

  bool displaySwapXyz;
  bool displayNearIntents;

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

  static const _swap = "Swap";

  static const _providers = [
    ExchangeProviderDescription.changeNow,
    ExchangeProviderDescription.sideShift,
    ExchangeProviderDescription.simpleSwap,
    ExchangeProviderDescription.trocador,
    ExchangeProviderDescription.exolix,
    ExchangeProviderDescription.chainflip,
    ExchangeProviderDescription.thorChain,
    ExchangeProviderDescription.letsExchange,
    ExchangeProviderDescription.stealthEx,
    ExchangeProviderDescription.xoSwap,
    ExchangeProviderDescription.swapTrade,
    ExchangeProviderDescription.swapsXyz,
    ExchangeProviderDescription.nearIntents,
  ];

  @override
  List<HistoryFilter> get filters => [
        HistoryFilter(
          key: _swap,
          caption: _swap,
          value: enabledProvidersCount > 0,
          children: [
            for (final provider in _providers)
              HistoryFilter(
                key: provider.title,
                caption: provider.title,
                value: _displaysProvider(provider),
                iconPath: provider.image,
              ),
          ],
        ),
      ];

  @override
  void toggleFilter(HistoryFilter filter) {
    if (filter.key == _swap) {
      toggleDisplayExchange(ExchangeProviderDescription.all);
      return;
    }

    final provider = _providers.firstWhereOrNull((provider) => provider.title == filter.key);

    if (provider != null) {
      toggleDisplayExchange(provider);
    }
  }

  @override
  void setAllFilters({required bool value}) {
    if (value != displayAllTrades) {
      toggleDisplayExchange(ExchangeProviderDescription.all);
    }
  }

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
      _displayByProvider[provider] ?? true;

  Map<ExchangeProviderDescription, bool> get _displayByProvider => {
        ExchangeProviderDescription.xmrto: displayXMRTO,
        ExchangeProviderDescription.morphToken: displayMorphToken,
        ExchangeProviderDescription.changeNow: displayChangeNow,
        ExchangeProviderDescription.sideShift: displaySideShift,
        ExchangeProviderDescription.simpleSwap: displaySimpleSwap,
        ExchangeProviderDescription.trocador: displayTrocador,
        ExchangeProviderDescription.exolix: displayExolix,
        ExchangeProviderDescription.chainflip: displayChainflip,
        ExchangeProviderDescription.thorChain: displayThorChain,
        ExchangeProviderDescription.letsExchange: displayLetsExchange,
        ExchangeProviderDescription.stealthEx: displayStealthEx,
        ExchangeProviderDescription.xoSwap: displayXOSwap,
        ExchangeProviderDescription.swapTrade: displaySwapTrade,
        ExchangeProviderDescription.swapsXyz: displaySwapXyz,
        ExchangeProviderDescription.nearIntents: displayNearIntents,
      };


  bool isTradeInAccount(Trade item, WalletBase wallet) =>
      item.fromWalletAddress == null
          ? true
          : wallet.walletAddresses.containsAddress(item.fromWalletAddress!);
}
