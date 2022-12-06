import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';

abstract class ExchangeProvider {
  ExchangeProvider({required this.pairList});
  
  String get title;
  List<ExchangePair> pairList;
  ExchangeProviderDescription get description;
  bool get isAvailable;
  bool get isEnabled;
  bool get supportsFixedRate;

  @override
  String toString() => title;

  Future<Limits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode});
  Future<Trade> createTrade({
    required TradeRequest request,
    required bool isFixedRateMode});
  Future<Trade> findTradeById({required String id});
  Future<double> calculateAmount({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required double amount,
    required bool isFixedRateMode,
    required bool isReceiveAmount});
  Future<bool> checkIsAvailable();
}
