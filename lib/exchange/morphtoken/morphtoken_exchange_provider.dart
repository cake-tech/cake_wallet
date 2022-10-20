import 'dart:convert';
import 'package:cake_wallet/core/amount_converter.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/exchange/trade_not_found_exeption.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/morphtoken/morphtoken_request.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade_not_created_exeption.dart';

class MorphTokenExchangeProvider extends ExchangeProvider {
  MorphTokenExchangeProvider({required this.trades})
      : super(pairList: [
          ExchangePair(from: CryptoCurrency.xmr, to: CryptoCurrency.eth),
          ExchangePair(from: CryptoCurrency.xmr, to: CryptoCurrency.bch),
          ExchangePair(from: CryptoCurrency.xmr, to: CryptoCurrency.ltc),
          ExchangePair(from: CryptoCurrency.xmr, to: CryptoCurrency.dash),
          ExchangePair(from: CryptoCurrency.dash, to: CryptoCurrency.btc),
          ExchangePair(from: CryptoCurrency.dash, to: CryptoCurrency.eth),
          ExchangePair(from: CryptoCurrency.dash, to: CryptoCurrency.bch),
          ExchangePair(from: CryptoCurrency.dash, to: CryptoCurrency.ltc),
          ExchangePair(from: CryptoCurrency.dash, to: CryptoCurrency.xmr),
          ExchangePair(from: CryptoCurrency.ltc, to: CryptoCurrency.btc),
          ExchangePair(from: CryptoCurrency.ltc, to: CryptoCurrency.eth),
          ExchangePair(from: CryptoCurrency.ltc, to: CryptoCurrency.bch),
          ExchangePair(from: CryptoCurrency.ltc, to: CryptoCurrency.dash),
          ExchangePair(from: CryptoCurrency.ltc, to: CryptoCurrency.xmr),
          ExchangePair(from: CryptoCurrency.bch, to: CryptoCurrency.btc),
          ExchangePair(from: CryptoCurrency.bch, to: CryptoCurrency.eth),
          ExchangePair(from: CryptoCurrency.bch, to: CryptoCurrency.ltc),
          ExchangePair(from: CryptoCurrency.bch, to: CryptoCurrency.dash),
          ExchangePair(from: CryptoCurrency.bch, to: CryptoCurrency.xmr),
          ExchangePair(from: CryptoCurrency.eth, to: CryptoCurrency.btc),
          ExchangePair(from: CryptoCurrency.eth, to: CryptoCurrency.bch),
          ExchangePair(from: CryptoCurrency.eth, to: CryptoCurrency.ltc),
          ExchangePair(from: CryptoCurrency.eth, to: CryptoCurrency.dash),
          ExchangePair(from: CryptoCurrency.eth, to: CryptoCurrency.xmr),
          ExchangePair(from: CryptoCurrency.btc, to: CryptoCurrency.eth),
          ExchangePair(from: CryptoCurrency.btc, to: CryptoCurrency.bch),
          ExchangePair(from: CryptoCurrency.btc, to: CryptoCurrency.ltc),
          ExchangePair(from: CryptoCurrency.btc, to: CryptoCurrency.dash),
          ExchangePair(from: CryptoCurrency.btc, to: CryptoCurrency.xmr)
        ]);

  Box<Trade> trades;

  static const apiUri = 'https://api.morphtoken.com';
  static const _morphURISuffix = '/morph';
  static const _limitsURISuffix = '/limits';
  static const _ratesURISuffix = '/rates';
  static const weight = 10000;

  @override
  String get title => 'MorphToken';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.morphToken;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Limits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode}) async {
    final url = apiUri + _limitsURISuffix;
    final uri = Uri.parse(url);
    final headers = {'Content-type': 'application/json'};
    final body = json.encode({
      "input": {"asset": from.toString()},
      "output": [
        {"asset": to.toString(), "weight": weight}
      ]
    });
    final response = await post(uri, headers: headers, body: body);
    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    final min = responseJSON['input']['limits']['min'] as int;
    int max = 0;
    double ethMax;

    if (from == CryptoCurrency.eth) {
      ethMax = responseJSON['input']['limits']['max'] as double;
    } else {
      max = responseJSON['input']['limits']['max'] as int;
    }

    final minFormatted = AmountConverter.amountIntToDouble(from, min);
    final maxFormatted = AmountConverter.amountIntToDouble(from, max);

    return Limits(min: minFormatted, max: maxFormatted);
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
    required bool isFixedRateMode}) async {
    const url = apiUri + _morphURISuffix;
    final _request = request as MorphTokenRequest;
    final body = {
      "input": {
        "asset": _request.from.toString(),
        "refund": _request.refundAddress
      },
      "output": [
        {
          "asset": _request.to.toString(),
          "weight": weight,
          "address": _request.address
        }
      ],
      "tag": "cakewallet"
    };
    final uri = Uri.parse(url);
    final response = await post(uri,
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
  Future<Trade> findTradeById({required String id}) async {
    final url = apiUri + _morphURISuffix + '/' + id;
    final uri = Uri.parse(url);
    final response = await get(uri);

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
    final from = CryptoCurrency.fromString(fromCurrency.toLowerCase());
    final toCurrency = responseJSON['output'][0]['asset'] as String;
    final to = CryptoCurrency.fromString(toCurrency.toLowerCase());
    final inputAddress = responseJSON['input']['deposit_address'] as String;
    final status = responseJSON['state'] as String;
    final state = TradeState.deserialize(raw: status.toLowerCase());

    String amount = "";
    for (final trade in trades.values) {
      if (trade.id == id) {
        amount = trade.amount;
        break;
      }
    }

    return Trade(
        id: id,
        from: from,
        to: to,
        provider: description,
        inputAddress: inputAddress,
        amount: amount,
        state: state);
  }

  @override
  Future<double> calculateAmount(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required double amount,
      required bool isFixedRateMode,
      required bool isReceiveAmount}) async {
    final url = apiUri + _ratesURISuffix;
    final uri = Uri.parse(url);
    final response = await get(uri);
    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final rate = responseJSON['data'][from.toString()][to.toString()] as String;

    try {
      final estimatedAmount = double.parse(rate) * amount;
      return estimatedAmount;
    } catch (_) {
      return 0.0;
    }
  }
}
