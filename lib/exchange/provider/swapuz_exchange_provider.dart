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

class SwapuzExchangeProvider extends ExchangeProvider {
  SwapuzExchangeProvider() : super(pairList: supportedPairs(_notSupported));

  static const List<CryptoCurrency> _notSupported = [];

  static const baseApiUrl = 'dev.api.swapuz.com';
  static const getRate = '/api/Home/v1/rate';
  static const createOrder = '/api/Home/v1/order';
  static const getOrder = '/api/Order/uid/';
  static const getLimits = '/api/Home/getLimits';

  // final partnerApiKey = secrets.swapuz;
  // final partnerAffiliateId = secrets.swapuzAffiliateId;

  String _networkFor(CryptoCurrency currency) {
    switch (currency) {
      default:
        return currency.tag != null ? currency.tag! : 'Mainnet';
    }
  }

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
    required bool isFixedRateMode,
    required bool isSendAll,
  }) async {
    try {
      var body = <String, dynamic>{
        'from': request.fromCurrency.title,
        'to': request.toCurrency.title,
        'fromNetwork': _networkFor(request.fromCurrency),
        'toNetwork': _networkFor(request.toCurrency),
        'address': request.toAddress,
        'amount': request.fromAmount,
        'modeCurs': isFixedRateMode ? 'fixed' : 'float',
      };

      final uri = await _getUri(createOrder, {});
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        body: json.encode(body),
      );

      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 400) {
        final error = responseBody['message'] as String;
        throw TradeNotCreatedException(description, description: error);
      }

      final responseData = responseBody['result'] as Map<String, dynamic>;

      return Trade(
        id: responseData["uid"] as String,
        from: request.fromCurrency,
        to: request.toCurrency,
        provider: description,
        inputAddress: responseData["addressFrom"] as String,
        amount: responseData["amount"].toString(),
        receiveAmount: responseData["amountResult"].toString(),
        createdAt: DateTime.parse(responseData["createDate"] as String),
        state: TradeState.created,
        payoutAddress: request.toAddress,
        isSendAll: isSendAll,
      );
    } catch (e) {
      printV("error creating trade: ${e.toString()}");
      throw TradeNotCreatedException(description, description: e.toString());
    }
  }

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.swapuz;

  @override
  Future<Limits> fetchLimits({
    required from,
    required to,
    required bool isFixedRateMode,
  }) async {
    try {
      final params = <String, dynamic>{
        'coin': from.title,
      };
      final uri = Uri.https(baseApiUrl, getLimits, params);
      final response = await ProxyWrapper().get(
        clearnetUri: uri,
      );
      final responseBody = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200)
        throw Exception('Unexpected http status: ${response.statusCode}');
      final data = responseBody['result'] as Map<String, dynamic>;
      return Limits(
        min: double.parse(data['minAmount'].toString()),
        max: double.parse(data['maxAmount'].toString()),
      );
    } catch (e) {
      printV("error fetching limits: ${e.toString()}");
      return Limits(min: 0, max: 0);
    }
  }

  @override
  Future<double> fetchRate({
    required from,
    required to,
    required double amount,
    required bool isFixedRateMode,
    required bool isReceiveAmount,
  }) async {
    try {
      if (amount == 0) return 0.0;

      final params = <String, dynamic>{
        'from': from.title,
        'to': to.title,
        'fromNetwork': from.title,
        'toNetwork': to.title,
        'amount': amount.toString(),
      };

      final uri = Uri.https(baseApiUrl, getRate, params);
      final response = await ProxyWrapper().get(clearnetUri: uri);

      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200)
        throw Exception('Unexpected http status: ${response.statusCode}');

      final data = responseBody['result'] as Map<String, dynamic>;
      double rate = double.parse(data['rate'].toString());
      return rate > 0
          ? isFixedRateMode
              ? amount / rate
              : rate / amount
          : 0.0;
    } catch (e) {
      printV("error fetching rate: ${e.toString()}");
      return 0.0;
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final uri = Uri.https(baseApiUrl, '$getOrder$id');
    final response = await ProxyWrapper().get(clearnetUri: uri);
    final responseBody = json.decode(response.body) as Map<String, dynamic>;

    if (responseBody['result'] == null) {
      throw TradeNotFoundException(id, provider: description);
    }
    final responseResult = responseBody['result'] as Map<String, dynamic>;
    return Trade(
      id: responseResult['uid'] as String,
      from: CryptoCurrency.fromString(responseResult['from']['name'] as String),
      to: CryptoCurrency.fromString(responseResult['to']['name'] as String),
      provider: description,
      inputAddress: responseResult['addressFrom'] as String,
      amount: responseResult['amount'].toString(),
      payoutAddress: responseResult['addressTo'] as String,
      state: TradeState.deserialize(raw: responseResult['status'].toString()),
      receiveAmount: responseResult['amountResult'].toString(),
      memo: responseResult['memoFrom'] as String?,
      createdAt: DateTime.parse(responseResult['createDate'] as String? ?? ''),
    );
  }

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  String get title => 'Swapuz';

  Future<Uri> _getUri(String path, Map<String, String> queryParams) async {
    final uri = Uri.https(baseApiUrl, path, queryParams);

    try {
      // Test connectivity to the base API URL
      await ProxyWrapper().get(clearnetUri: uri);
      return uri;
    } catch (e) {
      // If connection fails, return the same URI (no fallback for Swapuz)
      return uri;
    }
  }
}
