import 'dart:convert';

import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_not_created_exception.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/utils/currency_pairs_utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:http/http.dart' as http;

class XOSwapExchangeProvider extends ExchangeProvider {
  XOSwapExchangeProvider() : super(pairList: supportedPairs(_notSupported));

  static const List<CryptoCurrency> _notSupported = [];

  static const _apiAuthority = 'exchange.exodus.io';
  static const _apiPath = '/v3';
  static const _pairsPath = '/pairs';
  static const _ratePath = '/rates';
  static const _orders = '/orders';

  static const _headers = {'Content-Type': 'application/json', 'App-Name': 'cake-labs'};

  @override
  String get title => 'XOSwap';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.xoSwap;

  @override
  Future<bool> checkIsAvailable() async => true;

  Future<List<dynamic>> getRatesForPair({
    required CryptoCurrency from,
    required CryptoCurrency to,
  }) async {
    try {
      final curFrom = '${from.title}${_networkId(from)}';
      final curTo = '${to.title}${_networkId(to)}';
      final pairId = curFrom + '_' + curTo;
      final uri = Uri.https(_apiAuthority, '$_apiPath$_pairsPath/$pairId$_ratePath');
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode != 200) return [];
      return json.decode(response.body) as List<dynamic>;
    } catch (e) {
      printV(e.toString());
      return [];
    }
  }

  Future<Limits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    final rates = await getRatesForPair(from: from, to: to);
    if (rates.isEmpty) return Limits(min: 0, max: 0);

    double minLimit = double.infinity;
    double maxLimit = 0;

    for (var rate in rates) {
      final double currentMin = double.parse(rate['min']['value'].toString());
      final double currentMax = double.parse(rate['max']['value'].toString());
      if (currentMin < minLimit) minLimit = currentMin;
      if (currentMax > maxLimit) maxLimit = currentMax;
    }
    return Limits(min: minLimit, max: maxLimit);
  }

  Future<double> fetchRate({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required double amount,
    required bool isFixedRateMode,
    required bool isReceiveAmount,
  }) async {
    try {
      final rates = await getRatesForPair(from: from, to: to);
      if (rates.isEmpty) return 0;

      if (!isFixedRateMode) {
        double bestOutput = 0.0;
        for (var rate in rates) {
          final double minVal = double.parse(rate['min']['value'].toString());
          final double maxVal = double.parse(rate['max']['value'].toString());
          if (amount >= minVal && amount <= maxVal) {
            final double rateMultiplier = double.parse(rate['amount']['value'].toString());
            final double minerFee = double.parse(rate['minerFee']['value'].toString());
            final double outputAmount = (amount * rateMultiplier) - minerFee;
            if (outputAmount > bestOutput) {
              bestOutput = outputAmount;
            }
          }
        }
        return bestOutput > 0 ? (bestOutput / amount) : 0;
      } else {
        double bestInput = double.infinity;
        for (var rate in rates) {
          final double rateMultiplier = double.parse(rate['amount']['value'].toString());
          final double minerFee = double.parse(rate['minerFee']['value'].toString());
          final double minVal = double.parse(rate['min']['value'].toString());
          final double maxVal = double.parse(rate['max']['value'].toString());
          final double requiredSend = (amount + minerFee) / rateMultiplier;
          if (requiredSend >= minVal && requiredSend <= maxVal) {
            if (requiredSend < bestInput) {
              bestInput = requiredSend;
            }
          }
        }
        return bestInput < double.infinity ? amount / bestInput : 0;
      }
    } catch (e) {
      printV(e.toString());
      return 0;
    }
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
    required bool isFixedRateMode,
    required bool isSendAll,
  }) async {
    try {
      final uri = Uri.https(_apiAuthority, '$_apiPath$_orders');

      final payload = {
        'fromAmount': request.fromAmount,
        'fromAddress': request.refundAddress,
        'toAmount': request.toAmount,
        'toAddress': request.toAddress,
        'pairId': '${request.fromCurrency.title}_${request.toCurrency.title}',
      };

      final response = await http.post(uri, headers: _headers, body: json.encode(payload));
      if (response.statusCode != 201) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON['error'] ?? 'Unknown error';
        final message = responseJSON['message'] ?? '';
        throw Exception('$error\n$message');
      }
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;

      final amount = responseJSON['amount'] as Map<String, dynamic>;
      final toAmount = responseJSON['toAmount'] as Map<String, dynamic>;
      final orderId = responseJSON['id'] as String;
      final from = request.fromCurrency;
      final to = request.toCurrency;
      final payoutAddress = responseJSON['toAddress'] as String;
      final depositAddress = responseJSON['payInAddress'] as String;
      final refundAddress = responseJSON['fromAddress'] as String;
      final depositAmount = amount['value'] as double;
      final receiveAmount = toAmount['value'] as String;
      final status = responseJSON['status'] as String;
      final createdAtString = responseJSON['createdAt'] as String;
      final extraId = responseJSON['payInAddressTag'] as String?;

      final createdAt = DateTime.parse(createdAtString).toLocal();

      return Trade(
        id: orderId,
        from: from,
        to: to,
        provider: description,
        inputAddress: depositAddress,
        refundAddress: refundAddress,
        state: TradeState.deserialize(raw: status),
        createdAt: createdAt,
        amount: depositAmount.toString(),
        receiveAmount: receiveAmount.toString(),
        payoutAddress: payoutAddress,
        extraId: extraId,
      );
    } catch (e) {
      printV(e.toString());
      throw TradeNotCreatedException(description);
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    try {
      final uri = Uri.https(_apiAuthority, '$_apiPath$_orders/$id');
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode != 200) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        if (responseJSON.containsKey('code') && responseJSON['code'] == 'NOT_FOUND') {
          throw Exception('Trade not found');
        }
        final error = responseJSON['error'] ?? 'Unknown error';
        final message = responseJSON['message'] ?? responseJSON['details'] ?? '';
        throw Exception('$error\n$message');
      }
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;

      final pairId = responseJSON['pairId'] as String;
      final pairParts = pairId.split('_');
      final CryptoCurrency fromCurrency =
          CryptoCurrency.fromString(pairParts.isNotEmpty ? pairParts[0] : "");
      final CryptoCurrency toCurrency =
          CryptoCurrency.fromString(pairParts.length > 1 ? pairParts[1] : "");

      final amount = responseJSON['amount'] as Map<String, dynamic>;
      final toAmount = responseJSON['toAmount'] as Map<String, dynamic>;
      final orderId = responseJSON['id'] as String;
      final depositAmount = amount['value'] as String;
      final receiveAmount = toAmount['value'] as String;
      final depositAddress = responseJSON['payInAddress'] as String;
      final payoutAddress = responseJSON['toAddress'] as String;
      final refundAddress = responseJSON['fromAddress'] as String;
      final status = responseJSON['status'] as String;
      final createdAtString = responseJSON['createdAt'] as String;
      final createdAt = DateTime.parse(createdAtString).toLocal();
      final extraId = responseJSON['payInAddressTag'] as String?;

      return Trade(
        id: orderId,
        from: fromCurrency,
        to: toCurrency,
        provider: description,
        inputAddress: depositAddress,
        refundAddress: refundAddress,
        state: TradeState.deserialize(raw: status),
        createdAt: createdAt,
        amount: depositAmount,
        receiveAmount: receiveAmount,
        payoutAddress: payoutAddress,
        extraId: extraId,
      );
    } catch (e) {
      printV(e.toString());
      throw TradeNotCreatedException(description);
    }
  }

  String _networkId(CryptoCurrency currency) {
    if (currency.tag == 'POL') {
      if (currency.title.toUpperCase() == 'USDT') return 'matic86E249C1';

      if (currency.title.toUpperCase() == 'USDC') return 'matic0A883D9B';

      return '';
    }

    if (currency.tag == 'ETH') return '';

    return currency.tag ?? '';
  }
}
