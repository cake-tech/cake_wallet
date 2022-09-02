import 'package:flutter/foundation.dart';
import 'package:cw_core/crypto_currency.dart';
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
  bool get isAvailable;
  bool get isEnabled;

  @override
  String toString() => title;

  Future<Limits> fetchLimits(
      {CryptoCurrency from, CryptoCurrency to, bool isFixedRateMode});
  Future<Trade> createTrade({TradeRequest request, bool isFixedRateMode});
  Future<Trade> findTradeById({@required String id});
  Future<double> calculateAmount({CryptoCurrency from, CryptoCurrency to,
    double amount, bool isFixedRateMode, bool isReceiveAmount});
  Future<bool> checkIsAvailable();
}
