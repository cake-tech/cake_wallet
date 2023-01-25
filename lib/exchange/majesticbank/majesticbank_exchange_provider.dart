import 'dart:convert';
import 'package:cake_wallet/exchange/trade_not_found_exeption.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/majesticbank/majesticbank_request.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade_not_created_exeption.dart';

class MajesticBankExchangeProvider extends ExchangeProvider {
  MajesticBankExchangeProvider()
      : super(pairList: [
          ExchangePair(from: CryptoCurrency.xmr, to: CryptoCurrency.btc),
          ExchangePair(from: CryptoCurrency.btc, to: CryptoCurrency.xmr),
          ExchangePair(from: CryptoCurrency.ltc, to: CryptoCurrency.btc),
          ExchangePair(from: CryptoCurrency.btc, to: CryptoCurrency.ltc),
          ExchangePair(from: CryptoCurrency.xmr, to: CryptoCurrency.ltc),
          ExchangePair(from: CryptoCurrency.ltc, to: CryptoCurrency.xmr),]);

  static const referralCode = secrets.majesticBankPartnerCode;
  static const apiAuthority = 'majesticbank.is';
  static const createTradePath = '/api/v1/exchange';
  static const createFixedTradePath = '/api/v1/pay';
  static const findTradeByIdPath = '/api/v1/track';
  static const calculatePath = '/api/v1/calculate';
  static const limitsPath = '/api/v1/limits';

  @override
  String get title => 'Majestic Bank';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.majesticBank;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Limits> fetchLimits({
    required CryptoCurrency from, required CryptoCurrency to,
    required bool isFixedRateMode}) async {

    final normalizedFrom = normalizeCryptoCurrency(from);
    final params = <String, String>{
      'from_currency': normalizedFrom};
    final uri = Uri.https(apiAuthority, limitsPath, params);
    final response = await get(uri);

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['error'] as String;
      final message = responseJSON['message'] as String;
      throw Exception('${error}\n$message');
    }

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    double min = _toDouble(responseJSON['min']);
    double max = _toDouble(responseJSON['max']);
    return Limits(min: min, max: max);
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request, required bool isFixedRateMode}) async {

    final _request = request as MajesticBankRequest;
    final headers = <String, String>{
      'from_currency': normalizeCryptoCurrency(_request.from), 
      'receive_currency': normalizeCryptoCurrency(_request.to),
      'receive_address': _request.address,
      if (!isFixedRateMode) 'from_amount': _request.fromAmount,
      if (isFixedRateMode) 'receive_amount': _request.toAmount,
      'referral_code': referralCode
    };

    Uri uri;
    if (isFixedRateMode) {
      uri = Uri.https(apiAuthority, createFixedTradePath, headers);
    } else {
      uri = Uri.https(apiAuthority, createTradePath, headers);
    }

    final response = await get(uri);

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['error'] as String;
      final message = responseJSON['message'] as String;
      throw Exception('${error}\n$message');
    }

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final id = responseJSON['trx'] as String;
    final inputAddress = responseJSON['address'] as String;
    final fromAmount = responseJSON['from_amount'] as String;
    final expiration = _toDouble(responseJSON['expiration']);
    DateTime now = DateTime.now();
    DateTime expiredAt = now.add(Duration(minutes: expiration.round()));

    return Trade(
        id: id,
        from: _request.from,
        to: _request.to,
        provider: description,
        inputAddress: inputAddress,
        refundAddress: _request.refundAddress,
        createdAt: now,
        expiredAt: expiredAt,
        amount: fromAmount,
        state: TradeState.created);
  }

  @override
  Future<Trade> findTradeById({
    required String id}) async {

    final params = <String, String>{'trx': id};
    final uri = Uri.https(apiAuthority, findTradeByIdPath, params);
    final response = await get(uri);

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
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    CryptoCurrency from = CryptoCurrency();
    if (responseJSON.containsKey('from_currency')) {
      final fromCurrency = responseJSON['from_currency'] as String;
      from = CryptoCurrency.fromString(fromCurrency);
    }

    CryptoCurrency to = CryptoCurrency();
    if (responseJSON.containsKey('receive_currency')) {
      final toCurrency = responseJSON['receive_currency'] as String;
      to = CryptoCurrency.fromString(toCurrency);
    }

    final inputAddress = responseJSON['address'] as String;

    String expectedSendAmount = "";
    if (responseJSON.containsKey('from_amount')) {
      expectedSendAmount = responseJSON['from_amount'].toString();
    }

    double confirmed = 0;
    if (responseJSON.containsKey('confirmed')) {
      confirmed = _toDouble(responseJSON['confirmed']);
    }

    double receiveAmount = 0;
    if (responseJSON.containsKey('receive_amount')) {
      receiveAmount = _toDouble(responseJSON['receive_amount']);
    }

    double received = 0;
    if (responseJSON.containsKey('received')) {
      received = _toDouble(responseJSON['received']);
    }

    final status = responseJSON['status'] as String;
    final state = TradeState.deserialize(raw: _parseStatus(status));

    return Trade(
        id: id,
        from: from,
        to: to,
        provider: description,
        inputAddress: inputAddress,
        amount: expectedSendAmount,
        confirmed: confirmed,
        receiveAmount: receiveAmount,
        received: received,
        state: state);
  }

  @override
  Future<double> fetchRate(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required double amount,
      required bool isFixedRateMode,
      required bool isReceiveAmount}) async {

    try {
      if (amount == 0) {
        return 0.0;
      }

      final isReverse = isReceiveAmount;
      final params = <String, String>{
        'from_currency':isReverse ? normalizeCryptoCurrency(to) :
                                    normalizeCryptoCurrency(from),
        'receive_currency': isReverse ? normalizeCryptoCurrency(from) :
                                        normalizeCryptoCurrency(to),
        };

      if (isReverse) {
        params['receive_amount'] = amount.toString();
      } else {
        params['from_amount'] = amount.toString();
      }

      final uri = Uri.https(apiAuthority, calculatePath, params);
      final response = await get(uri);
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final fromAmount = _toDouble(responseJSON['from_amount']);
      final toAmount = _toDouble(responseJSON['receive_amount']);

      return isReverse ? fromAmount : toAmount;
    } catch(e) {
      print(e.toString());
      return 0.0;
    }
  }

  static String _parseStatus(String input) {
    if (input == "Waiting for funds") {
      return "waitingPayment";
    }
    if (input == "Completed") {
      return "complete";
    }
    return input;
  }

  static double _toDouble(dynamic input) {
    return double.parse(input.toString());
  }

  static String normalizeCryptoCurrency(CryptoCurrency currency) {
    return currency.title.toUpperCase();
  }
}
