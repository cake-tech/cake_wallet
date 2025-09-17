import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_not_created_exception.dart';
import 'package:cake_wallet/exchange/trade_not_found_exception.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/utils/currency_pairs_utils.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';

class SwapTradeExchangeProvider extends ExchangeProvider {
  SwapTradeExchangeProvider() : super(pairList: supportedPairs(_notSupported));

  static final List<CryptoCurrency> _notSupported = [
    ...(CryptoCurrency.all
        .where((element) => ![
              CryptoCurrency.btc,
              CryptoCurrency.sol,
              CryptoCurrency.eth,
              CryptoCurrency.ltc,
              CryptoCurrency.ada,
              CryptoCurrency.bch,
              CryptoCurrency.usdterc20,
              CryptoCurrency.usdttrc20,
              CryptoCurrency.bnb,
              CryptoCurrency.xmr,
              CryptoCurrency.zec,
            ].contains(element))
        .toList())
  ];

  static final markup = secrets.swapTradeExchangeMarkup;

  static const apiAuthority = 'api.swaptrade.io';
  static const getRate = '/api/swap/get-rate';
  static const getCoins = '/api/swap/get-coins';
  static const createOrder = '/api/swap/create-order';
  static const order = '/api/swap/order';

  @override
  String get title => 'SwapTrade';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.swapTrade;

  static const _headers = <String, String>{'Content-Type': 'application/json'};

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Limits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    try {
      final uri = Uri.https(apiAuthority, getCoins);
      final response = await ProxyWrapper().get(clearnetUri: uri);
      

      final responseJSON = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200)
        throw Exception('Unexpected http status: ${response.statusCode}');

      final coinsInfo = responseJSON['data'] as List<dynamic>;

      final coin = coinsInfo.firstWhere(
            (coin) => coin['id'].toString().toUpperCase() == _normalizeCurrency(from),
        orElse: () => null,
      );

      if (coin == null) throw Exception('Coin not found: ${_normalizeCurrency(from)}');

      return Limits(
        min: double.parse(coin['min'].toString()),
        max: double.parse(coin['max'].toString()),
      );
    } catch (e) {
      printV(e.toString());
      throw Exception('Error fetching limits: ${e.toString()}');
    }
  }

  @override
  Future<double> fetchRate({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required double amount,
    required bool isFixedRateMode,
    required bool isReceiveAmount,
    String? senderAddress,
    String? recipientAddress,
  }) async {
    try {
      if (amount == 0) return 0.0;

      final params = <String, dynamic>{};
      final body = <String, String>{
        'coin_send': _normalizeCurrency(from),
        'coin_receive': _normalizeCurrency(to),
        'amount': amount.toString(),
        'ref': 'cake',
      };

      final uri = Uri.https(apiAuthority, getRate, params);
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        body: json.encode(body),
        headers: _headers,
      );
      
      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200)
        throw Exception('Unexpected http status: ${response.statusCode}');

      final data = responseBody['data'] as Map<String, dynamic>;
      double rate = double.parse(data['price'].toString());
      return rate > 0 ? isFixedRateMode ? amount / rate : rate / amount : 0.0;
    } catch (e) {
      printV("error fetching rate: ${e.toString()}");
      return 0.0;
    }
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
    required bool isFixedRateMode,
    required bool isSendAll,
  }) async {
    try {
      final params = <String, dynamic>{};
      var body = <String, dynamic>{
        'coin_send': _normalizeCurrency(request.fromCurrency),
        'coin_send_network': _networkFor(request.fromCurrency),
        'coin_receive': _normalizeCurrency(request.toCurrency),
        'coin_receive_network': _networkFor(request.toCurrency),
        'amount_send': request.fromAmount,
        'recipient': request.toAddress,
        'ref': 'cake',
        'markup': markup,
        'refund_address': request.refundAddress,
      };

      final uri = Uri.https(apiAuthority, createOrder, params);
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        body: json.encode(body),
        headers: _headers,
      );
      
      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 400 || responseBody["success"] == false) {
        final error = responseBody['errors'][0]['msg'] as String;
        throw TradeNotCreatedException(description, description: error);
      }

      if (response.statusCode != 200)
        throw Exception('Unexpected http status: ${response.statusCode}');

      final responseData = responseBody['data'] as Map<String, dynamic>;
      final receiveAmount = responseData["amount_receive"]?.toString();

      return Trade(
        id: responseData["order_id"] as String,
        inputAddress: responseData["server_address"] as String,
        amount: request.fromAmount,
        receiveAmount: receiveAmount ?? request.toAmount,
        from: request.fromCurrency,
        to: request.toCurrency,
        provider: description,
        createdAt: DateTime.now(),
        state: TradeState.created,
        payoutAddress: request.toAddress,
        isSendAll: isSendAll,
        userCurrencyFromRaw: '${request.fromCurrency.title}_${request.fromCurrency.tag ?? ''}',
        userCurrencyToRaw: '${request.toCurrency.title}_${request.toCurrency.tag ?? ''}',
      );
    } catch (e) {
      printV("error creating trade: ${e.toString()}");
      throw TradeNotCreatedException(description, description: e.toString());
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    try {
      final params = <String, dynamic>{};
      var body = <String, dynamic>{
        'order_id': id,
      };

      final uri = Uri.https(apiAuthority, order, params);
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        body: json.encode(body),
        headers: _headers,
      );
      
      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 400 || responseBody["success"] == false) {
        final error = responseBody['errors'][0]['msg'] as String;
        throw TradeNotCreatedException(description, description: error);
      }

      if (response.statusCode != 200)
        throw Exception('Unexpected http status: ${response.statusCode}');

      final responseData = responseBody['data'] as Map<String, dynamic>;
      final fromCurrency = responseData['coin_send'] as String;
      final from = CryptoCurrency.safeParseCurrencyFromString(fromCurrency);
      final toCurrency = responseData['coin_receive'] as String;
      final to = CryptoCurrency.safeParseCurrencyFromString(toCurrency);
      final inputAddress = responseData['server_address'] as String;
      final payoutAddress = responseData['recipient'] as String;
      final status = responseData['status'] as String;
      final state = TradeState.deserialize(raw: status);
      final response_id = responseData['order_id'] as String;
      final expectedSendAmount = responseData['amount_send'] as String;
      final expectedReceiveAmount = responseData['amount_receive'] as String;
      final memo = responseData['memo'] as String?;
      final createdAt = responseData['created_at'] as String?;

      return Trade(
        id: response_id,
        from: from,
        to: to,
        provider: description,
        inputAddress: inputAddress,
        amount: expectedSendAmount,
        payoutAddress: payoutAddress,
        state: state,
        receiveAmount: expectedReceiveAmount,
        memo: memo,
        createdAt: DateTime.tryParse(createdAt ?? ''),
        userCurrencyFromRaw: '${fromCurrency.toUpperCase()}' + '_',
        userCurrencyToRaw: '${toCurrency.toUpperCase()}' + '_',
      );
    } catch (e) {
      printV("error getting trade: ${e.toString()}");
      throw TradeNotFoundException(
        id,
        provider: description,
        description: e.toString(),
      );
    }
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    switch (currency) {
      default:
        return currency.title.toUpperCase();
    }
  }

  String _networkFor(CryptoCurrency currency) {
    final network = switch (currency) {
      CryptoCurrency.eth => 'ETH',
      CryptoCurrency.bnb => 'BNB_BSC',
      CryptoCurrency.usdterc20 => 'USDT_ERC20',
      CryptoCurrency.usdttrc20 => 'TRX_USDT_S2UZ',
      _ => '',
    };
    return network;
  }
}
