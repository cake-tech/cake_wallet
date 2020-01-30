import 'dart:convert';
import 'package:cake_wallet/src/domain/exchange/trade_not_found_exeption.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_pair.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/limits.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/domain/exchange/trade_request.dart';
import 'package:cake_wallet/src/domain/exchange/trade_state.dart';
import 'package:cake_wallet/src/domain/exchange/morphtoken/morphtoken_request.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/domain/exchange/trade_not_created_exeption.dart';

class MorphTokenExchangeProvider extends ExchangeProvider {
  MorphTokenExchangeProvider()
      : super(
      pairList: CryptoCurrency.all
          .map((i) {
        return CryptoCurrency.all.map((k) {
          if (i == CryptoCurrency.btc && k == CryptoCurrency.xmr) {
            return ExchangePair(from: i, to: k, reverse: false);
          }

          if (i == CryptoCurrency.xmr && k == CryptoCurrency.btc) {
            return null;
          }

          return ExchangePair(from: i, to: k, reverse: true);
        }).where((c) => c != null);
      })
          .expand((i) => i)
          .toList());

  static const apiUri = 'https://api.morphtoken.com';
  static const _morphURISuffix = '/morph';
  static const _limitsURISuffix = '/limits';
  static const _ratesURISuffix = '/rates';
  static const weight = 10000;

  @override
  String get title => 'MorphToken';

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.morphToken;

  @override
  Future<Limits> fetchLimits({CryptoCurrency from, CryptoCurrency to}) async {
    final url = apiUri + _limitsURISuffix;
    final headers = {'Content-type': 'application/json'};
    final body =
    json.encode({
      "input": {
        "asset": from.toString()
      },
      "output": [{
        "asset": to.toString(),
        "weight": weight
      }]});
    final response =
    await post(url.toString(), headers: headers, body: json.encode(body));
    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    final min = responseJSON['input']['limits']['min'] as double;
    final max = responseJSON['input']['limits']['max'] as double;

    return Limits(min: min, max: max);
  }

  @override
  Future<Trade> createTrade({TradeRequest request}) async {
    const url = apiUri + _morphURISuffix;
    final _request = request as MorphTokenRequest;
    final body = {
      "input": {
        "asset": _request.from.toString(),
        "refund": _request.refundAddress
      },
      "output": [{
        "asset": _request.to.toString(),
        "weight": weight,
        "address": _request.address
      }]
    };

    final response = await post(url,
        headers: {'Content-Type': 'application/json'}, body: json.encode(body));

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON['description'] as String;

        throw TradeNotCreatedException(description, description: error);
      }

      throw TradeNotCreatedException(description);
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final id = responseJSON['id'] as String;

    return Trade(
        id: id,
        provider: description,
        from: _request.from,
        to: _request.to,
        state: TradeState.created,
        amount: _request.amount,
        createdAt: DateTime.now());
  }

  @override
  Future<Trade> findTradeById({@required String id}) async {
    final url = apiUri + _morphURISuffix + '/' + id;
    final response = await get(url);

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON['description'] as String;

        throw TradeNotFoundException(id,
            provider: description, description: error);
      }

      throw TradeNotFoundException(id, provider: description);
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final fromCurrency = responseJSON['input']['asset'] as String;
    final from = CryptoCurrency.fromString(fromCurrency);
    final toCurrency = responseJSON['output']['asset'] as String;
    final to = CryptoCurrency.fromString(toCurrency);
    final inputAddress = responseJSON['input']['refund_address'] as String;
    final outputWeight = responseJSON['output']['weight'].toString();
    final status = responseJSON['state'] as String;
    final state = TradeState.deserialize(raw: status);
    final extraId = responseJSON['id'] as String;
    final outputTransaction = responseJSON['deposit_address'] as String;

    return Trade(
        id: id,
        from: from,
        to: to,
        provider: description,
        inputAddress: inputAddress,
        amount: outputWeight,
        state: state,
        extraId: extraId,
        outputTransaction: outputTransaction);
  }

  @override
  Future<double> calculateAmount(
      {CryptoCurrency from, CryptoCurrency to, double amount}) async {
    final url = apiUri + _ratesURISuffix;
    final response = await get(url);
    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final rate = responseJSON['data'][from.toString()][to.toString()] as String;
    final estimatedAmount = double.parse(rate) * amount;

    return estimatedAmount;
  }
}
