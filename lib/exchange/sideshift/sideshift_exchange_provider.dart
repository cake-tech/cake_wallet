import 'dart:convert';

import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/sideshift/sideshift_request.dart';
import 'package:cake_wallet/exchange/trade_not_created_exeption.dart';
import 'package:cake_wallet/exchange/trade_not_found_exeption.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

class SideShiftExchangeProvider extends ExchangeProvider {
  SideShiftExchangeProvider()
      : super(
            pairList: CryptoCurrency.all
                .map((i) => CryptoCurrency.all
                    .map((k) => ExchangePair(from: i, to: k, reverse: true))
                    .where((c) => c != null))
                .expand((i) => i)
                .toList());

  static const affiliateId = secrets.sideShiftAffiliateId;
  static const apiBaseUrl = 'https://sideshift.ai/api';
  static const rangePath = '/v1/pairs';
  static const orderPath = '/v1/orders';
  static const quotePath = '/v1/quotes';
  static const permissionPath = '/v1/permissions';

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.sideShift;

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
      final fromCurrency = _normalizeCryptoCurrency(from);
      final toCurrency = _normalizeCryptoCurrency(to);
      final url =
          apiBaseUrl + rangePath + '/' + fromCurrency + '/' + toCurrency;
      final response = await get(url);
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final rate = double.parse(responseJSON['rate'] as String);
      final max = double.parse(responseJSON['max'] as String);

      if (amount > max) return 0.00;

      final estimatedAmount = rate * amount;

      return estimatedAmount;
    } catch (_) {
      return 0.00;
    }
  }

  @override
  Future<bool> checkIsAvailable() async {
    const url = apiBaseUrl + permissionPath;
    final response = await get(url);

    if (response.statusCode == 500) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['error']['message'] as String;

      throw Exception('$error');
    }

    if (response.statusCode != 200) {
      return false;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final canCreateOrder = responseJSON['createOrder'] as bool;
    final canCreateQuote = responseJSON['createQuote'] as bool;
    return canCreateOrder && canCreateQuote;
  }

  @override
  Future<Trade> createTrade(
      {TradeRequest request, bool isFixedRateMode}) async {
    final _request = request as SideShiftRequest;
    final quoteId = await _createQuote(_request);
    final url = apiBaseUrl + orderPath;
    final headers = {'Content-Type': 'application/json'};
    final body = {
      'type': 'fixed',
      'quoteId': quoteId,
      'affiliateId': affiliateId,
      'settleAddress': _request.settleAddress,
      'refundAddress': _request.refundAddress
    };
    final response = await post(url, headers: headers, body: json.encode(body));

    if (response.statusCode != 201) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON['error']['message'] as String;

        throw TradeNotCreatedException(description, description: error);
      }

      throw TradeNotCreatedException(description);
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final id = responseJSON['id'] as String;
    final inputAddress = responseJSON['depositAddress']['address'] as String;
    final settleAddress = responseJSON['settleAddress']['address'] as String;

    return Trade(
      id: id,
      provider: description,
      from: _request.depositMethod,
      to: _request.settleMethod,
      inputAddress: inputAddress,
      refundAddress: settleAddress,
      state: TradeState.created,
      amount: _request.depositAmount,
      createdAt: DateTime.now(),
    );
  }

  Future<String> _createQuote(SideShiftRequest request) async {
    final url = apiBaseUrl + quotePath;
    final headers = {'Content-Type': 'application/json'};
    final depositMethod = _normalizeCryptoCurrency(request.depositMethod);
    final settleMethod = _normalizeCryptoCurrency(request.settleMethod);
    final body = {
      'depositMethod': depositMethod,
      'settleMethod': settleMethod,
      'affiliateId': affiliateId,
      'depositAmount': request.depositAmount,
    };
    final response = await post(url, headers: headers, body: json.encode(body));

    if (response.statusCode != 201) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON['error']['message'] as String;

        throw TradeNotCreatedException(description, description: error);
      }

      throw TradeNotCreatedException(description);
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final quoteId = responseJSON['id'] as String;

    return quoteId;
  }

  @override
  Future<Limits> fetchLimits(
      {CryptoCurrency from, CryptoCurrency to, bool isFixedRateMode}) async {
    final fromCurrency = _normalizeCryptoCurrency(from);
    final toCurrency = _normalizeCryptoCurrency(to);
    final url = apiBaseUrl + rangePath + '/' + fromCurrency + '/' + toCurrency;
    final response = await get(url);

    if (response.statusCode == 500) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['error']['message'] as String;

      throw Exception('$error');
    }

    if (response.statusCode != 200) {
      return null;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final min = double.parse(responseJSON['min'] as String);
    final max = double.parse(responseJSON['max'] as String);

    return Limits(min: min, max: max);
  }

  @override
  Future<Trade> findTradeById({@required String id}) async {
    final url = apiBaseUrl + orderPath + '/' + id;
    final response = await get(url);

    if (response.statusCode == 404) {
      throw TradeNotFoundException(id, provider: description);
    }

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['error']['message'] as String;

      throw TradeNotFoundException(id,
          provider: description, description: error);
    }

    if (response.statusCode != 200) {
      return null;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final fromCurrency = responseJSON['depositMethodId'] as String;
    final from = CryptoCurrency.fromString(fromCurrency);
    final toCurrency = responseJSON['settleMethodId'] as String;
    final to = CryptoCurrency.fromString(toCurrency);
    final inputAddress = responseJSON['depositAddress']['address'] as String;
    final expectedSendAmount = responseJSON['depositAmount'].toString();
    final deposits = responseJSON['deposits'] as List;
    TradeState state;

    if (deposits != null && deposits.isNotEmpty) {
      final status = deposits[0]['status'] as String;
      state = TradeState.deserialize(raw: status);
    }

    final expiredAtRaw = responseJSON['expiresAtISO'] as String;
    final expiredAt =
        expiredAtRaw != null ? DateTime.parse(expiredAtRaw).toLocal() : null;

    return Trade(
      id: id,
      from: from,
      to: to,
      provider: description,
      inputAddress: inputAddress,
      amount: expectedSendAmount,
      state: state,
      expiredAt: expiredAt,
    );
  }

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  String get title => 'SideShift';

  static String _normalizeCryptoCurrency(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.zaddr:
        return 'zaddr';
      case CryptoCurrency.zec:
        return 'zec';
      case CryptoCurrency.bnb:
        return currency.tag.toLowerCase();
      case CryptoCurrency.usdterc20:
        return 'usdtErc20';
      default:
        return currency.title.toLowerCase();
    }
  }
}
