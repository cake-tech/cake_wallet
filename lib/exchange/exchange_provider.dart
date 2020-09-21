import 'package:flutter/foundation.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';

abstract class ExchangeProvider {
  ExchangeProvider({this.pairList});
  
  String get title;
  List<ExchangePair> pairList;
  ExchangeProviderDescription description;

  @override
  String toString() => title;

  Future<Limits> fetchLimits({CryptoCurrency from, CryptoCurrency to});
  Future<Trade> createTrade({TradeRequest request});
  Future<Trade> findTradeById({@required String id});
  Future<double> calculateAmount(
      {CryptoCurrency from, CryptoCurrency to, double amount});
}
