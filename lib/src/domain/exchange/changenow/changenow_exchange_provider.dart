import 'dart:convert';
import 'package:cake_wallet/src/domain/exchange/trade_not_found_exeption.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_pair.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/limits.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/domain/exchange/trade_request.dart';
import 'package:cake_wallet/src/domain/exchange/trade_state.dart';
import 'package:cake_wallet/src/domain/exchange/changenow/changenow_request.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/domain/exchange/trade_not_created_exeption.dart';

class ChangeNowExchangeProvider extends ExchangeProvider {
  static const apiUri = 'https://changenow.io/api/v1';
  static const apiKey = secrets.change_now_api_key;
  static const _exchangeAmountUriSufix = '/exchange-amount/';
  static const _transactionsUriSufix = '/transactions/';
  static const _minAmountUriSufix = '/min-amount/';

  String get title => 'ChangeNOW';
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.changeNow;

  ChangeNowExchangeProvider() {
    pairList = CryptoCurrency.all
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
        .toList();
  }

  Future<Limits> fetchLimits({CryptoCurrency from, CryptoCurrency to}) async {
    final symbol = from.toString() + '_' + to.toString();
    final url = apiUri + _minAmountUriSufix + symbol;
    final response = await get(url);
    final responseJSON = json.decode(response.body);
    final double min = responseJSON['minAmount'];

    return Limits(min: min, max: null);
  }

  Future<Trade> createTrade({TradeRequest request}) async {
    const url = apiUri + _transactionsUriSufix + apiKey;
    final _request = request as ChangeNowRequest;
    final body = {
      'from': _request.from.toString(),
      'to': _request.to.toString(),
      'address': _request.address,
      'amount': _request.amount,
      'refundAddress': _request.refundAddress
    };

    final response = await post(url,
        headers: {'Content-Type': 'application/json'}, body: json.encode(body));

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body);
        final error = responseJSON['message'];
        throw TradeNotCreatedException(description, description: error);
      }

      throw TradeNotCreatedException(description);
    }

    final responseJSON = json.decode(response.body);

    return Trade(
        id: responseJSON['id'],
        from: _request.from,
        to: _request.to,
        provider: description,
        inputAddress: responseJSON['payinAddress'],
        refundAddress: responseJSON['refundAddress'],
        extraId: responseJSON["payinExtraId"],
        createdAt: DateTime.now(),
        amount: _request.amount,
        state: TradeState.created);
  }

  Future<Trade> findTradeById({@required String id}) async {
    final url = apiUri + _transactionsUriSufix + id + '/' + apiKey;
    final response = await get(url);

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body);
        final error = responseJSON['message'];
        throw TradeNotFoundException(id,
            provider: description, description: error);
      }

      throw TradeNotFoundException(id, provider: description);
    }

    final responseJSON = json.decode(response.body);
    
    return Trade(
        id: id,
        from: CryptoCurrency.fromString(responseJSON['fromCurrency']),
        to: CryptoCurrency.fromString(responseJSON['toCurrency']),
        provider: description,
        inputAddress: responseJSON['payinAddress'],
        amount: responseJSON['expectedSendAmount'].toString(),
        state: TradeState.deserialize(raw: responseJSON['status']),
        extraId: responseJSON['payinExtraId'],
        outputTransaction: responseJSON['payoutHash']);
  }

  Future<double> calculateAmount(
      {CryptoCurrency from, CryptoCurrency to, double amount}) async {
    final url = apiUri +
        _exchangeAmountUriSufix +
        amount.toString() +
        '/' +
        from.toString() +
        '_' +
        to.toString();
    final response = await get(url);
    final responseJSON = json.decode(response.body);

    return responseJSON['estimatedAmount'];
  }
}
