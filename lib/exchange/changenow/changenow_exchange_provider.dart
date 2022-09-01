import 'dart:convert';
import 'package:cake_wallet/exchange/trade_not_found_exeption.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/changenow/changenow_request.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade_not_created_exeption.dart';

class ChangeNowExchangeProvider extends ExchangeProvider {
  ChangeNowExchangeProvider()
      : _lastUsedRateId = '',
        super(
            pairList: CryptoCurrency.all
                .map((i) => CryptoCurrency.all
                    .map((k) => ExchangePair(from: i, to: k, reverse: true))
                    .where((c) => c != null))
                .expand((i) => i)
                .toList());

  static const apiKey = secrets.changeNowApiKey;
  static const apiAuthority = 'api.changenow.io';
  static const createTradePath = '/v2/exchange';
  static const findTradeByIdPath = '/v2/exchange/by-id';
  static const estimatedAmountPath = '/v2/exchange/estimated-amount';
  static const rangePath = '/v2/exchange/range';
  static const apiHeaderKey = 'x-changenow-api-key';

  @override
  String get title => 'ChangeNOW';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.changeNow;

  @override
  Future<bool> checkIsAvailable() async => true;

  String _lastUsedRateId;

  static String getFlow(bool isFixedRate) => isFixedRate ? 'fixed-rate' : 'standard';

  @override
  Future<Limits> fetchLimits({CryptoCurrency from, CryptoCurrency to,
    bool isFixedRateMode}) async {
    final headers = {apiHeaderKey: apiKey};
    final normalizedFrom = normalizeCryptoCurrency(from);
    final normalizedTo = normalizeCryptoCurrency(to);
    final flow = getFlow(isFixedRateMode);
    final params = <String, String>{
      'fromCurrency': normalizedFrom,
      'toCurrency': normalizedTo,
      'fromNetwork': networkFor(from),
      'toNetwork': networkFor(to),
      'flow': flow};
    final uri = Uri.https(apiAuthority, rangePath, params);
    final response = await get(uri, headers: headers);
    
    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['error'] as String;
      final message = responseJSON['message'] as String;
      throw Exception('${error}\n$message');
    }

    if (response.statusCode != 200) {
      return null;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    return Limits(
      min: responseJSON['minAmount'] as double,
      max: responseJSON['maxAmount'] as double);
  }

  @override
  Future<Trade> createTrade({TradeRequest request, bool isFixedRateMode}) async {
    final _request = request as ChangeNowRequest;
    final headers = {
      apiHeaderKey: apiKey,
      'Content-Type': 'application/json'};
    final flow = getFlow(isFixedRateMode);
    final body = <String, String>{
      'fromCurrency': normalizeCryptoCurrency(_request.from), 
      'toCurrency': normalizeCryptoCurrency(_request.to),
      'fromNetwork': networkFor(_request.from),
      'toNetwork': networkFor(_request.to),
      'fromAmount': _request.fromAmount, 
      'toAmount': _request.toAmount, 
      'address': _request.address,
      'flow': flow,
      'refundAddress': _request.refundAddress
    };

    if (isFixedRateMode) {
      body['rateId'] = _lastUsedRateId;
    }

    final uri = Uri.https(apiAuthority, createTradePath);
    final response = await post(uri, headers: headers, body: json.encode(body));
    
    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['error'] as String;
      final message = responseJSON['message'] as String;
      throw Exception('${error}\n$message');
    }

    if (response.statusCode != 200) {
      return null;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final id = responseJSON['id'] as String;
    final inputAddress = responseJSON['payinAddress'] as String;
    final refundAddress = responseJSON['refundAddress'] as String;
    final extraId = responseJSON['payinExtraId'] as String;

    return Trade(
        id: id,
        from: _request.from,
        to: _request.to,
        provider: description,
        inputAddress: inputAddress,
        refundAddress: refundAddress,
        extraId: extraId,
        createdAt: DateTime.now(),
        amount: _request.fromAmount,
        state: TradeState.created);
  }

  @override
  Future<Trade> findTradeById({@required String id}) async {
    final headers = {apiHeaderKey: apiKey};
    final params = <String, String>{'id': id};
    final uri = Uri.https(apiAuthority,findTradeByIdPath, params);
    final response = await get(uri, headers: headers);

    if (response.statusCode == 404) {
      throw TradeNotFoundException(id, provider: description);
    }

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['message'] as String;

      throw TradeNotFoundException(id,
          provider: description, description: error);
    }

    if (response.statusCode != 200) {
      return null;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final fromCurrency = responseJSON['fromCurrency'] as String;
    final from = CryptoCurrency.fromString(fromCurrency);
    final toCurrency = responseJSON['toCurrency'] as String;
    final to = CryptoCurrency.fromString(toCurrency);
    final inputAddress = responseJSON['payinAddress'] as String;
    final expectedSendAmount = responseJSON['expectedAmountFrom'].toString();
    final status = responseJSON['status'] as String;
    final state = TradeState.deserialize(raw: status);
    final extraId = responseJSON['payinExtraId'] as String;
    final outputTransaction = responseJSON['payoutHash'] as String;
    final expiredAtRaw = responseJSON['validUntil'] as String;
    final expiredAt = expiredAtRaw != null
        ? DateTime.parse(expiredAtRaw).toLocal()
        : null;

    return Trade(
        id: id,
        from: from,
        to: to,
        provider: description,
        inputAddress: inputAddress,
        amount: expectedSendAmount,
        state: state,
        extraId: extraId,
        expiredAt: expiredAt,
        outputTransaction: outputTransaction);
  }

  @override
  Future<double> calculateAmount(
      {CryptoCurrency from,
      CryptoCurrency to,
      double amount,
      bool isFixedRateMode,
      bool isReceiveAmount}) async {
    try {
      if (amount == 0) {
        return 0.0;
      }

      final headers = {apiHeaderKey: apiKey};
      final isReverse = isReceiveAmount;
      final type = isReverse ? 'reverse' : 'direct';
      final flow = getFlow(isFixedRateMode);
      final params = <String, String>{
        'fromCurrency': isReverse ? normalizeCryptoCurrency(to) : normalizeCryptoCurrency(from),
        'toCurrency': isReverse ? normalizeCryptoCurrency(from) : normalizeCryptoCurrency(to),
        'fromNetwork': isReverse ? networkFor(to) : networkFor(from),
        'toNetwork': isReverse ? networkFor(from) : networkFor(to),
        'type': type,
        'flow': flow};

      if (isReverse) {
        params['toAmount'] = amount.toString();
      } else {
        params['fromAmount'] = amount.toString();
      }
      
      final uri = Uri.https(apiAuthority, estimatedAmountPath, params);
      final response = await get(uri, headers: headers);
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final fromAmount = double.parse(responseJSON['fromAmount'].toString());
      final toAmount =  double.parse(responseJSON['toAmount'].toString());
      final rateId = responseJSON['rateId'] as String ?? '';

      if (rateId.isNotEmpty) {
        _lastUsedRateId = rateId;
      }

      return isReverse ? fromAmount : toAmount;
    } catch(e) {
      print(e.toString());
      return 0.0;
    }
  }
 
  String networkFor(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.usdt:
        return CryptoCurrency.btc.title.toLowerCase();
      default:
        return currency.tag != null
            ? currency.tag.toLowerCase()
            : currency.title.toLowerCase();
      }
    }
  }

   String normalizeCryptoCurrency(CryptoCurrency currency) {
   switch(currency) {
      case CryptoCurrency.zec:
        return 'zec';
      default:
        return currency.title.toLowerCase();
    }

  }
