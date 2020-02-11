import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/changenow/changenow_exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/domain/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/morphtoken/morphtoken_exchange_provider.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:hive/hive.dart';

part 'exchange_trade_store.g.dart';

class ExchangeTradeStore = ExchangeTradeStoreBase with _$ExchangeTradeStore;

abstract class ExchangeTradeStoreBase with Store {
  ExchangeTradeStoreBase(
      {@required this.trade, @required WalletStore walletStore, @required this.trades}) {
    isSendable = trade.from == walletStore.type ||
        trade.provider == ExchangeProviderDescription.xmrto;

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
    }

    _updateTrade();
    _timer = Timer.periodic(Duration(seconds: 20), (_) async => _updateTrade());
  }

  @observable
  Trade trade;

  @observable
  bool isSendable;

  Box<Trade> trades;

  ExchangeProvider _provider;

  Timer _timer;

  @override
  void dispose() {
    super.dispose();

    if (_timer != null) {
      _timer.cancel();
    }
  }

  @action
  Future<void> _updateTrade() async {
    try {
      final updatedTrade = await _provider.findTradeById(id: trade.id);

      if (updatedTrade.createdAt == null && trade.createdAt != null) {
        updatedTrade.createdAt = trade.createdAt;
      }

      trade = updatedTrade;
    } catch (e) {
      print(e.toString());
    }
  }
}
