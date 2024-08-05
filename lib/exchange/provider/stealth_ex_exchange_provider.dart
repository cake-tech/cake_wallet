import 'dart:convert';
import 'dart:developer';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_not_created_exception.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/utils/currency_pairs_utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:http/http.dart' as http;

class StealthExExchangeProvider extends ExchangeProvider {
  StealthExExchangeProvider() : super(pairList: supportedPairs(_notSupported));

  static const List<CryptoCurrency> _notSupported = [];

  static const apiKey = secrets.stealthExBearerToken;
  static const _baseUrl = 'https://api.stealthex.io';
  static const _rangePath = '/v4/rates/range';
  static const _amountPath = '/v4/rates/estimated-amount';
  static const _exchangesPath = '/v4/exchanges';

  @override
  String get title => 'StealthEx';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.stealthEx;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Limits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode}) async {
    final headers = {'Authorization': apiKey, 'Content-Type': 'application/json'};
    final body = {
      'route': {
        'from': {'symbol': isFixedRateMode ? to.name : from.name, 'network': 'mainnet'},
        'to': {'symbol': isFixedRateMode ? from.name : to.name, 'network': 'mainnet'}
      },
      'estimation': isFixedRateMode ? 'reversed' : 'direct',
      'rate': isFixedRateMode ? 'fixed' : 'floating'
    };

    try {
      final response = await http.post(Uri.parse(_baseUrl + _rangePath),
          headers: headers, body: json.encode(body));
      if (response.statusCode != 200) {
        throw Exception('StealthEx fetch limits failed: ${response.body}');
      }
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final min = responseJSON['min_amount'] as double?;
      final max = responseJSON['max_amount'] as double?;
      return Limits(min: min, max: max);
    } catch (e) {
      log(e.toString());
      throw Exception('StealthEx failed to fetch limits');
    }
  }

  @override
  Future<double> fetchRate(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required double amount,
      required bool isFixedRateMode,
      required bool isReceiveAmount}) async {
    final response = await getEstimatedExchangeAmount(
        from: from, to: to, amount: amount, isFixedRateMode: isFixedRateMode);
    final estimatedAmount = response['estimated_amount'] as double? ?? 0.0;
    return estimatedAmount > 0.0
        ? isFixedRateMode
            ? amount / estimatedAmount
            : estimatedAmount / amount
        : 0.0;
  }

  @override
  Future<Trade> createTrade(
      {required TradeRequest request,
      required bool isFixedRateMode,
      required bool isSendAll}) async {
    String? rateId;
    String? validUntil;

    try {
      if (isFixedRateMode) {
        final response = await getEstimatedExchangeAmount(
            from: request.fromCurrency,
            to: request.toCurrency,
            amount: double.parse(request.toAmount),
            isFixedRateMode: isFixedRateMode);
        rateId = response['rate_id'] as String?;
        validUntil = response['valid_until'] as String?;
        if (rateId == null) throw TradeNotCreatedException(description);
      }

      final headers = {'Authorization': apiKey, 'Content-Type': 'application/json'};
      final body = {
        'route': {
          'from': {'symbol': request.fromCurrency.name, 'network': 'mainnet'},
          'to': {'symbol': request.toCurrency.name, 'network': 'mainnet'}
        },
        'estimation': isFixedRateMode ? 'reversed' : 'direct',
        'rate': isFixedRateMode ? 'fixed' : 'floating',
        if (isFixedRateMode) 'rate_id': rateId,
        'amount':
            isFixedRateMode ? double.parse(request.toAmount) : double.parse(request.fromAmount),
        'address': request.toAddress,
        'refund_address': request.refundAddress,
      };

      final response = await http.post(Uri.parse(_baseUrl + _exchangesPath),
          headers: headers, body: json.encode(body));

      if (response.statusCode != 201) {
        throw Exception('StealthEx create trade failed: ${response.body}');
      }
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final deposit = responseJSON['deposit'] as Map<String, dynamic>;
      final withdrawal = responseJSON['withdrawal'] as Map<String, dynamic>;

      final id = responseJSON['id'] as String;
      final from = deposit['symbol'] as String;
      final to = withdrawal['symbol'] as String;
      final payoutAddress = withdrawal['address'] as String;
      final depositAddress = deposit['address'] as String;
      final refundAddress = responseJSON['refund_address'] as String;
      final depositAmount = toDouble(deposit['amount']);
      final receiveAmount = toDouble(withdrawal['amount']);
      final status = responseJSON['status'] as String;
      final createdAtString = responseJSON['created_at'] as String;

      final createdAt = DateTime.parse(createdAtString);
      final expiredAt = validUntil != null
          ? DateTime.parse(validUntil)
          : DateTime.now().add(Duration(minutes: 5));

      return Trade(
        id: id,
        from: CryptoCurrency.fromString(from),
        to: CryptoCurrency.fromString(to),
        provider: description,
        inputAddress: depositAddress,
        payoutAddress: payoutAddress,
        refundAddress: refundAddress,
        amount: depositAmount.toString(),
        receiveAmount: receiveAmount.toString(),
        state: TradeState.deserialize(raw: status),
        createdAt: createdAt,
        expiredAt: expiredAt,
      );
    } catch (e) {
      log(e.toString());
      throw TradeNotCreatedException(description);
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final headers = {'Authorization': apiKey, 'Content-Type': 'application/json'};

    final uri = Uri.parse('$_baseUrl$_exchangesPath/$id');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('StealthEx fetch trade failed: ${response.body}');
    }
    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final deposit = responseJSON['deposit'] as Map<String, dynamic>;
    final withdrawal = responseJSON['withdrawal'] as Map<String, dynamic>;

    final respId = responseJSON['id'] as String;
    final from = deposit['symbol'] as String;
    final to = withdrawal['symbol'] as String;
    final payoutAddress = withdrawal['address'] as String;
    final depositAddress = deposit['address'] as String;
    final refundAddress = responseJSON['refund_address'] as String;
    final depositAmount = toDouble(deposit['amount']);
    final receiveAmount = toDouble(withdrawal['amount']);
    final status = responseJSON['status'] as String;
    final createdAtString = responseJSON['created_at'] as String;
    final createdAt = DateTime.parse(createdAtString);

    return Trade(
      id: respId,
      from: CryptoCurrency.fromString(from),
      to: CryptoCurrency.fromString(to),
      provider: description,
      inputAddress: depositAddress,
      payoutAddress: payoutAddress,
      refundAddress: refundAddress,
      amount: depositAmount.toString(),
      receiveAmount: receiveAmount.toString(),
      state: TradeState.deserialize(raw: status),
      createdAt: createdAt,
      isRefund: status == 'refunded',
    );
  }

  Future<Map<String, dynamic>> getEstimatedExchangeAmount(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required double amount,
      required bool isFixedRateMode}) async {
    final headers = {'Authorization': apiKey, 'Content-Type': 'application/json'};

    final body = {
      'route': {
        'from': {'symbol': from.name, 'network': 'mainnet'},
        'to': {'symbol': to.name, 'network': 'mainnet'}
      },
      'estimation': isFixedRateMode ? 'reversed' : 'direct',
      'rate': isFixedRateMode ? 'fixed' : 'floating',
      'amount': amount
    };

    try {
      final response = await http.post(Uri.parse(_baseUrl + _amountPath),
          headers: headers, body: json.encode(body));
      if (response.statusCode != 200) return {};
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final rate = responseJSON['rate'] as Map<String, dynamic>?;
      return {
        'estimated_amount': responseJSON['estimated_amount'] as double?,
        if (rate != null) 'valid_until': rate['valid_until'] as String?,
        if (rate != null) 'rate_id': rate['id'] as String?
      };
    } catch (e) {
      log(e.toString());
      return {};
    }
  }

  double toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      return 0.0;
    }
  }
}
