import 'dart:convert';

import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/utils/currency_pairs_utils.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:http/http.dart' as http;

class ThorChainExchangeProvider extends ExchangeProvider {
  ThorChainExchangeProvider({required SettingsStore settingsStore})
      : _settingsStore = settingsStore,
        super(pairList: supportedPairs(_notSupported));

  static final List<CryptoCurrency> _notSupported = [
    ...(CryptoCurrency.all
        .where((element) => ![CryptoCurrency.btc, CryptoCurrency.eth].contains(element))
        .toList())
  ];

  static const _baseURL = 'https://thornode.ninerealms.com';
  static const _quotePath = '/thorchain/quote/swap';

  final SettingsStore _settingsStore;

  @override
  String get title => 'ThorChain';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.thorChain;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Limits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode}) async {
    final params = {
      'from_asset': _normalizeCurrency(from),
      'to_asset': _normalizeCurrency(to),
      'amount': '100000000',
    };

    final url = Uri.parse('$_baseURL$_quotePath${Uri(queryParameters: params)}');
    final response = await http.get(url);

    if (response.statusCode != 200)
      throw Exception('Unexpected http status: ${response.statusCode}');

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final minAmountIn = responseJSON['recommended_min_amount_in'] as String?;
    final formattedMinAmountIn = minAmountIn != null ? double.parse(minAmountIn) / 100000000 : 0.0;

    return Limits(min: formattedMinAmountIn);
  }

  @override
  Future<Trade> createTrade({required TradeRequest request, required bool isFixedRateMode}) async {
    double amountBTC = double.parse(request.fromAmount);
    int amountSatoshi = (amountBTC * 100000000).toInt();
    String formattedAmount = amountSatoshi.toString();

    final params = {
      'from_asset': _normalizeCurrency(request.fromCurrency),
      'to_asset': _normalizeCurrency(request.toCurrency),
      'amount': formattedAmount,
      'destination': request.toAddress,
    };
    final url = Uri.parse('$_baseURL$_quotePath${Uri(queryParameters: params)}');
    final response = await http.get(url);

    if (response.statusCode != 200)
      throw Exception('Unexpected http status: ${response.statusCode}');

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final inputAddress = responseJSON['inbound_address'] as String?;

    return Trade(
        id: 'id',
        from: request.fromCurrency,
        to: request.toCurrency,
        provider: description,
        inputAddress: inputAddress,
        refundAddress: 'refundAddress',
        extraId: 'extraId',
        createdAt: DateTime.now(),
        amount: request.fromAmount,
        state: TradeState.created,
        payoutAddress: request.toAddress);
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
        'amount': (amount * 100000000).toInt().toString(),
      };

      final url = Uri.parse('$_baseURL$_quotePath${Uri(queryParameters: params)}');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Unexpected http status: ${response.statusCode}');
      }

      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      print(responseJSON.toString());

      final expectedAmountOutString = responseJSON['expected_amount_out'] as String? ?? '0';
      final expectedAmountOut = double.parse(expectedAmountOutString);

      double formattedAmountOut = expectedAmountOut / 1e9;

      return formattedAmountOut;
    } catch (e) {
      print(e.toString());
      return 0.0;
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) {
    throw UnimplementedError('findTradeById');
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.btc:
        return 'BTC.BTC';
      case CryptoCurrency.eth:
        return 'ETH.ETH';
      default:
        return currency.title.toLowerCase();
    }
  }
}
