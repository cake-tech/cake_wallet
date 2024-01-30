import 'dart:convert';

import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/utils/currency_pairs_utils.dart';
import 'package:collection/collection.dart';
import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ThorChainExchangeProvider extends ExchangeProvider {
  ThorChainExchangeProvider({required this.tradesStore})
      : super(pairList: supportedPairs(_notSupported));

  static final List<CryptoCurrency> _notSupported = [
    ...(CryptoCurrency.all
        .where((element) => ![
              CryptoCurrency.btc,
              CryptoCurrency.eth,
              CryptoCurrency.ltc,
            ].contains(element))
        .toList())
  ];

  static const _baseURL = 'https://thornode.ninerealms.com';
  static const _quotePath = '/thorchain/quote/swap';
  static const _affiliateName = 'cakewallet';
  static const _affiliateBps = '10';

  final Box<Trade> tradesStore;

  @override
  String get title => 'ThorChain';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.thorChain;

  @override
  Future<bool> checkIsAvailable() async => true;

  Future<Map<String, dynamic>> _getSwapQuote(Map<String, String> params) async {
    final uri = Uri.parse('$_baseURL$_quotePath${Uri(queryParameters: params)}');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Unexpected HTTP status: ${response.statusCode}');
    }

    if (response.body.contains('error')) {
      throw Exception('Unexpected response: ${response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<Limits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode}) async {
    final params = {
      'from_asset': _normalizeCurrency(from),
      'to_asset': _normalizeCurrency(to),
      'amount': AmountConverter.amountToSmallestUnit(cryptoCurrency: from, amount: 1).toString(),
      'affiliate': _affiliateName,
      'affiliate_bps': _affiliateBps
    };

    final responseJSON = await _getSwapQuote(params);
    final minAmountIn = responseJSON['recommended_min_amount_in'] as String?;
    final formattedMinAmountIn = minAmountIn != null ? int.parse(minAmountIn) / 1e8 : 0.0;

    return Limits(min: formattedMinAmountIn);
  }

  @override
  Future<Trade> createTrade({required TradeRequest request, required bool isFixedRateMode}) async {
    double amountBTC = double.parse(request.fromAmount);
    String formattedAmount = AmountConverter.amountToSmallestUnit(
            cryptoCurrency: request.fromCurrency, amount: amountBTC)
        .toString();

    final params = {
      'from_asset': _normalizeCurrency(request.fromCurrency),
      'to_asset': _normalizeCurrency(request.toCurrency),
      'amount': formattedAmount,
      'destination': request.toAddress,
      'affiliate': _affiliateName,
      'affiliate_bps': _affiliateBps
    };

    final responseJSON = await _getSwapQuote(params);

    final inputAddress = responseJSON['inbound_address'] as String?;
    final memo = responseJSON['memo'] as String?;
    final tradeId = await getNextTradeCounter();

    return Trade(
        id: tradeId.toString(),
        from: request.fromCurrency,
        to: request.toCurrency,
        provider: description,
        inputAddress: inputAddress,
        createdAt: DateTime.now(),
        amount: request.fromAmount,
        state: TradeState.created,
        payoutAddress: request.toAddress,
        memo: memo);
  }

  @override
  Future<double> fetchRate(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required double amount,
      required bool isFixedRateMode,
      required bool isReceiveAmount}) async {
    try {
      if (amount == 0) return 0.0;

      final params = {
        'from_asset': _normalizeCurrency(from),
        'to_asset': _normalizeCurrency(to),
        'amount':
            AmountConverter.amountToSmallestUnit(cryptoCurrency: from, amount: amount).toString(),
      };

      final responseJSON = await _getSwapQuote(params);

      final expectedAmountOutString = responseJSON['expected_amount_out'] as String? ?? '0';
      final expectedAmountOut = double.parse(expectedAmountOutString);
      double formattedAmountOut = 0.0;

      if (to == CryptoCurrency.eth) {
        formattedAmountOut = expectedAmountOut / 1e9;
      } else {
        formattedAmountOut = AmountConverter.amountIntToDouble(to, expectedAmountOut.toInt());
      }

      return formattedAmountOut;
    } catch (e) {
      print(e.toString());
      return 0.0;
    }
  }

  Future<Trade> findTradeById({required String id}) async {
    final foundTrade = tradesStore.values.firstWhereOrNull((element) => element.id == id);
    if (foundTrade == null) {
      throw Exception('Trade with id $id not found');
    }
    return foundTrade;
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.btc:
        return 'BTC.BTC';
      case CryptoCurrency.eth:
        return 'ETH.ETH';
      case CryptoCurrency.ltc:
        return 'LTC.LTC';
      case CryptoCurrency.bch:
        return 'BCH.BCH';
      default:
        return currency.title.toLowerCase();
    }
  }

  Future<int> getNextTradeCounter() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCounter = prefs.getInt(PreferencesKey.thorChainTradeCounter) ?? 0;
    currentCounter++;
    await prefs.setInt(PreferencesKey.thorChainTradeCounter, currentCounter);
    return currentCounter;
  }
}
