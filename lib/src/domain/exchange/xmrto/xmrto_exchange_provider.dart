import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_pair.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/limits.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/domain/exchange/trade_request.dart';
import 'package:cake_wallet/src/domain/exchange/trade_state.dart';
import 'package:cake_wallet/src/domain/exchange/xmrto/xmrto_trade_request.dart';
import 'package:cake_wallet/src/domain/exchange/trade_not_created_exeption.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/src/domain/exchange/trade_not_found_exeption.dart';

class XMRTOExchangeProvider extends ExchangeProvider {
  static const userAgent = 'CakeWallet/XMR iOS';
  static const originalApiUri = 'https://xmr.to/api/v2/xmr2btc';
  static const proxyApiUri = 'https://xmrproxy.net/api/v2/xmr2btc';
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

  String get title => 'XMR.TO';

  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.xmrto;

  List<ExchangePair> pairList = [
    ExchangePair(
        from: CryptoCurrency.xmr, to: CryptoCurrency.btc, reverse: false)
  ];

  double _rate = 0;

  Future<Limits> fetchLimits({CryptoCurrency from, CryptoCurrency to}) async {
    final url = await getApiUri() + _orderParameterUriSufix;
    final response = await get(url);

    if (response.statusCode != 200) {
      return Limits(min: 0, max: 0);
    }

    final responseJSON = json.decode(response.body);
    final double min = responseJSON['lower_limit'];
    final double max = responseJSON['upper_limit'];

    return Limits(min: min, max: max);
  }

  Future<Trade> createTrade({TradeRequest request}) async {
    final _request = request as XMRTOTradeRequest;
    final url = await getApiUri() + _orderCreateUriSufix;
    final body = {
      'btc_amount': _request.amount,
      'btc_dest_address': _request.address
    };
    final response = await post(url,
        headers: {'Content-Type': 'application/json'}, body: json.encode(body));

    if (response.statusCode != 201) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body);
        throw TradeNotCreatedException(description,
            description: responseJSON['error_msg']);
      }

      throw TradeNotCreatedException(description);
    }

    final responseJSON = json.decode(response.body);
    final uuid = responseJSON["uuid"];

    return Trade(
        id: uuid,
        provider: description,
        from: _request.from,
        to: _request.to,
        state: TradeState.created,
        amount: _request.amount,
        createdAt: DateTime.now());
  }

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
        final responseJSON = json.decode(response.body);
        final error = responseJSON['error_msg'];
        throw TradeNotFoundException(id,
            provider: description, description: error);
      }

      throw TradeNotFoundException(id, provider: description);
    }

    final responseJSON = json.decode(response.body);
    final address = responseJSON['xmr_receiving_integrated_address'];
    final paymentId = responseJSON['xmr_required_payment_id_short'];
    final amount = responseJSON['xmr_amount_total'].toString();
    final stateRaw = responseJSON['state'];
    final expiredAtRaw = responseJSON['expires_at'];
    final expiredAt = DateTime.parse(expiredAtRaw).toLocal();
    final outputTransaction = responseJSON['btc_transaction_id'];
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

  Future<double> calculateAmount(
      {CryptoCurrency from, CryptoCurrency to, double amount}) async {
    if (from != CryptoCurrency.xmr && to != CryptoCurrency.btc) {
      return 0;
    }

    if (_rate == null || _rate == 0) {
      _rate = await _fetchRates();
    }

    final double result = _rate * amount;

    return double.parse(result.toStringAsFixed(12));
  }

  Future<double> _fetchRates() async {
    try {
      final url = await getApiUri() + _orderParameterUriSufix;
      final response =
          await get(url, headers: {'Content-Type': 'application/json'});
      final responseJSON = json.decode(response.body);
      double btcprice = responseJSON['price'];
      double price = 1 / btcprice;
      return price;
    } catch (e) {
      print(e.toString());
      return 0.0;
    }
  }
}
