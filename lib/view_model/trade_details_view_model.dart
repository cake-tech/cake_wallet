import 'dart:async';
import 'package:cake_wallet/exchange/changenow/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/morphtoken/morphtoken_exchange_provider.dart';
import 'package:cake_wallet/exchange/sideshift/sideshift_exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/trade_details/track_trade_list_item.dart';
import 'package:url_launcher/url_launcher.dart';

part 'trade_details_view_model.g.dart';

class TradeDetailsViewModel = TradeDetailsViewModelBase
    with _$TradeDetailsViewModel;

abstract class TradeDetailsViewModelBase with Store {
  TradeDetailsViewModelBase({Trade tradeForDetails, this.trades}) {
    trade = tradeForDetails;

    switch (trade.provider) {
      case ExchangeProviderDescription.xmrto:
        _provider = XMRTOExchangeProvider();
        break;
      case ExchangeProviderDescription.changeNow:
        _provider = ChangeNowExchangeProvider();
        break;
      case ExchangeProviderDescription.morphToken:
        _provider = MorphTokenExchangeProvider(trades: trades);
        break;
      case ExchangeProviderDescription.sideshift:
        _provider = SideShiftExchangeProvider(trade: trade);
        break;
    }

    items = ObservableList<StandartListItem>();

    _updateItems();

    _updateTrade();

    _timer = Timer.periodic(Duration(seconds: 20), (_) async => _updateTrade());
  }

  final Box<Trade> trades;

  @observable
  Trade trade;

  @observable
  ObservableList<StandartListItem> items;

  ExchangeProvider _provider;

  Timer _timer;

  @action
  Future<void> _updateTrade() async {
    try {
      final updatedTrade = await _provider.findTradeById(id: trade.id);

      if (updatedTrade.createdAt == null && trade.createdAt != null) {
        updatedTrade.createdAt = trade.createdAt;
      }

      trade = updatedTrade;

      _updateItems();
    } catch (e) {
      print(e.toString());
    }
  }

  void _updateItems() {
    final dateFormat = DateFormatter.withCurrentLocal();

    items?.clear();

    items.addAll([
      StandartListItem(title: S.current.trade_details_id, value: trade.id),
      StandartListItem(
          title: S.current.trade_details_state,
          value: trade.state != null
              ? trade.state.toString()
              : S.current.trade_details_fetching)
    ]);

    if (trade.provider != null) {
      items.add(StandartListItem(
          title: S.current.trade_details_provider,
          value: trade.provider.toString()));
    }

    if (trade.provider == ExchangeProviderDescription.changeNow) {
      final buildURL =
          'https://changenow.io/exchange/txs/${trade.id.toString()}';
      items.add(TrackTradeListItem(
          title: 'Track',
          value: buildURL,
          onTap: () {
            launch(buildURL);
          }));
    }

    if (trade.provider == ExchangeProviderDescription.sideshift) {
      final buildURL =
          'https://sideshift.ai/orders/${trade.id.toString()}';
      items.add(TrackTradeListItem(
          title: 'Track',
          value: buildURL,
          onTap: () {
            launch(buildURL);
          }));
    }

    if (trade.createdAt != null) {
      items.add(StandartListItem(
          title: S.current.trade_details_created_at,
          value: dateFormat.format(trade.createdAt).toString()));
    }

    if (trade.from != null && trade.to != null) {
      items.add(StandartListItem(
          title: S.current.trade_details_pair,
          value: '${trade.from.toString()} → ${trade.to.toString()}'));
    }
  }
}
