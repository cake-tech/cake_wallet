import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/trade_request.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_pair.dart';
import 'package:cake_wallet/src/domain/exchange/limits.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';

abstract class ExchangeProvider {
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
