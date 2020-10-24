import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/xmrto/xmrto_trade_request.dart';
import 'package:cake_wallet/exchange/trade_not_created_exeption.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade_not_found_exeption.dart';

class XMRTOExchangeProvider extends ExchangeProvider {
  XMRTOExchangeProvider()
      : super(pairList: [
          ExchangePair(
              from: CryptoCurrency.xmr, to: CryptoCurrency.btc, reverse: false)
        ]);

  static const userAgent = 'CakeWallet/XMR iOS';
  static const originalApiUri = 'https://xmr.to/api/v3/xmr2btc';
  static const proxyApiUri = 'https://xmrproxy.net/api/v3/xmr2btc';
  static const _orderParameterUriSufix = '/order_parameter_query';
  static const _orderStatusUriSufix = '/order_status_query/';
  static const _orderCreateUriSufix = '/order_create/';
  static String _apiUri = '';

  static Future<String> getApiUri() async {
    if (_apiUri != null && _apiUri.isNotEmpty) {
      return _apiUri;
    }

    const url = originalApiUri + _orderParameterUriSufix;
    final response =
        await get(url, headers: {'Content-Type': 'application/json'});
    _apiUri = response.statusCode == 403 ? proxyApiUri : originalApiUri;

    return _apiUri;
  }

  @override
  String get title => 'XMR.TO';

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.xmrto;

  double _rate = 0;

  @override
  Future<Limits> fetchLimits({CryptoCurrency from, CryptoCurrency to}) async {
    final url = await getApiUri() + _orderParameterUriSufix;
    final response = await get(url);
    final correction = 0.001;

    if (response.statusCode != 200) {
      return Limits(min: 0, max: 0);
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    double min = double.parse(responseJSON['lower_limit'] as String);
    double max = double.parse(responseJSON['upper_limit'] as String);
    final price = double.parse(responseJSON['price'] as String);

    if (price > 0) {
      try {
        min = min/price + correction;
        min = _limitsFormat(min);
        max = max/price - correction;
        max = _limitsFormat(max);
      } catch (e) {
        min = 0;
        max = 0;
      }
    } else {
      min = 0;
      max = 0;
    }

    return Limits(min: min, max: max);
  }

  @override
  Future<Trade> createTrade({TradeRequest request}) async {
    final _request = request as XMRTOTradeRequest;
    final url = await getApiUri() + _orderCreateUriSufix;
    final body = {
      'amount': _request.isBTCRequest
          ? _request.receiveAmount.replaceAll(',', '.')
          : _request.amount.replaceAll(',', '.'),
      'amount_currency': _request.isBTCRequest
          ? _request.to.toString()
          : _request.from.toString(),
      'btc_dest_address': _request.address
    };
    final response = await post(url,
        headers: {'Content-Type': 'application/json'}, body: json.encode(body));

    if (response.statusCode != 201) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON['error_msg'] as String;

        throw TradeNotCreatedException(description, description: error);
      }

      throw TradeNotCreatedException(description);
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final uuid = responseJSON["uuid"] as String;

    return Trade(
        id: uuid,
        provider: description,
        from: _request.from,
        to: _request.to,
        state: TradeState.created,
        amount: _request.amount,
        createdAt: DateTime.now());
  }

  @override
  Future<Trade> findTradeById({@required String id}) async {
    const headers = {
      'Content-Type': 'application/json',
      'User-Agent': userAgent
    };
    final url = await getApiUri() + _orderStatusUriSufix;
    final body = {'uuid': id};
    final response = await post(url, headers: headers, body: json.encode(body));

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON['error_msg'] as String;

        throw TradeNotFoundException(id,
            provider: description, description: error);
      }

      throw TradeNotFoundException(id, provider: description);
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final address = responseJSON['receiving_subaddress'] as String;
    final paymentId = responseJSON['xmr_required_payment_id_short'] as String;
    final amount = responseJSON['incoming_amount_total'].toString();
    final stateRaw = responseJSON['state'] as String;
    final expiredAtRaw = responseJSON['expires_at'] as String;
    final expiredAt = DateTime.parse(expiredAtRaw).toLocal();
    final outputTransaction = responseJSON['btc_transaction_id'] as String;
    final state = TradeState.deserialize(raw: stateRaw);

    return Trade(
        id: id,
        provider: description,
        from: CryptoCurrency.xmr,
        to: CryptoCurrency.btc,
        inputAddress: address,
        extraId: paymentId,
        expiredAt: expiredAt,
        amount: amount,
        state: state,
        outputTransaction: outputTransaction);
  }

  @override
  Future<double> calculateAmount(
      {CryptoCurrency from, CryptoCurrency to, double amount,
        bool isReceiveAmount}) async {
    if (from != CryptoCurrency.xmr && to != CryptoCurrency.btc) {
      return 0;
    }

    if (_rate == null || _rate == 0) {
      _rate = await _fetchRates();
    }

    final double result = isReceiveAmount
        ? _rate == 0 ? 0 : amount / _rate
        : _rate * amount;

    return double.parse(result.toStringAsFixed(12));
  }

  Future<double> _fetchRates() async {
    try {
      final url = await getApiUri() + _orderParameterUriSufix;
      final response =
          await get(url, headers: {'Content-Type': 'application/json'});
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final price = double.parse(responseJSON['price'] as String);

      return price;
    } catch (e) {
      print(e.toString());
      return 0.0;
    }
  }

  double _limitsFormat(double limit) => double.parse(limit.toStringAsFixed(3));
}
