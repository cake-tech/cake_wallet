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
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cake_wallet/utils/exchange_provider_logger.dart';
class XOSwapExchangeProvider extends ExchangeProvider {
  XOSwapExchangeProvider() : super(pairList: supportedPairs(_notSupported));

  static const List<CryptoCurrency> _notSupported = [];

  static const _apiAuthority = 'exchange.exodus.io';
  static const _apiPath = '/v3';
  static const _pairsPath = '/pairs';
  static const _ratePath = '/rates';
  static const _orders = '/orders';
  static const _assets = '/assets';

  static const _headers = {'Content-Type': 'application/json', 'App-Name': 'cake-labs'};

  final _networks = <String, String>{
    'POL': 'matic',
    'ETH': 'ethereum',
    'BTC': 'bitcoin',
    'BSC': 'bsc',
    'SOL': 'solana',
    'TRX': 'tronmainnet',
    'ZEC': 'zcash',
    'ADA': 'cardano',
    'DOGE': 'dogecoin',
    'XMR': 'monero',
    'BCH': 'bcash',
    'BSV': 'bitcoinsv',
    'XRP': 'ripple',
    'LTC': 'litecoin',
    'EOS': 'eosio',
    'XLM': 'stellar',
  };

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

  Future<String?> _getAssets(CryptoCurrency currency) async {
    if (currency.tag == null) return currency.title;
    try {
      final normalizedNetwork = _networks[currency.tag];
      if (normalizedNetwork == null) return null;

      final uri = Uri.https(_apiAuthority, _apiPath + _assets,
          {'networks': normalizedNetwork, 'query': currency.title});

      final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch assets for ${currency.title} on ${currency.tag}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw const FormatException('Unexpected response format');
      final assets = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();


      final asset = assets.firstWhere(
        (asset) => removeNonAlphanumeric((asset['symbol'] ?? '').toString()) == currency.title,
        orElse: () => const {},
      );

      return asset.isEmpty ? null : asset['id'] as String;
    } catch (e) {
      printV(e.toString());
      return null;
    }
  }

  String removeNonAlphanumeric(String str) => str.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  Future<List<dynamic>> getRatesForPair({
    required CryptoCurrency from,
    required CryptoCurrency to,
  }) async {
    try {
      final curFrom = await _getAssets(from);
      final curTo = await _getAssets(to);
      if (curFrom == null || curTo == null) return [];
      final pairId = curFrom + '_' + curTo;
      final uri = Uri.https(_apiAuthority, '$_apiPath$_pairsPath/$pairId$_ratePath');
      final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

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
    try {
      final rates = await getRatesForPair(from: from, to: to);
      if (rates.isEmpty) throw Exception('No rates found for $from to $to');

    double minLimit = double.infinity;
    double maxLimit = 0;

      for (var rate in rates) {
        final double currentMin = double.parse(rate['min']['value'].toString());
        final double currentMax = double.parse(rate['max']['value'].toString());
        if (currentMin < minLimit) minLimit = currentMin;
        if (currentMax > maxLimit) maxLimit = currentMax;
      }
      return Limits(min: minLimit, max: maxLimit);
    } catch (e) {
      printV(e.toString());
      throw Exception('StealthEx failed to fetch limits');
    }
  }

  @override
  Future<double> fetchRate({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required double amount,
    required bool isFixedRateMode,
    required bool isReceiveAmount,
    String? senderAddress,
    String? recipientAddress,
  }) async {
    try {
      final rates = await getRatesForPair(from: from, to: to);
      if (rates.isEmpty) {
        ExchangeProviderLogger.logError(
          provider: description,
          function: 'fetchRate',
          error: Exception('No rates found for $from to $to'),
          stackTrace: StackTrace.current,
          requestData: {
            'from': from.title,
            'to': to.title,
            'amount': amount,
            'isFixedRateMode': isFixedRateMode,
            'isReceiveAmount': isReceiveAmount,
          },
        );
        return 0;
      }

      double result;
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
        result = bestOutput > 0 ? (bestOutput / amount) : 0;
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
        result = bestInput < double.infinity ? amount / bestInput : 0;
      }

      ExchangeProviderLogger.logSuccess(
        provider: description,
        function: 'fetchRate',
        requestData: {
          'from': from.title,
          'to': to.title,
          'amount': amount,
          'isFixedRateMode': isFixedRateMode,
          'isReceiveAmount': isReceiveAmount,
        },
        responseData: {
          'result': result,
          'ratesCount': rates.length,
          'rates': rates,
        },
      );

      return result;
    } catch (e, s) {
      ExchangeProviderLogger.logError(
        provider: description,
        function: 'fetchRate',
        error: e,
        stackTrace: s,
        requestData: {
          'from': from.title,
          'to': to.title,
          'amount': amount,
          'isFixedRateMode': isFixedRateMode,
          'isReceiveAmount': isReceiveAmount,
        },
      );
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

      final curFrom = await _getAssets(request.fromCurrency);
      final curTo = await _getAssets(request.toCurrency);

      if (curFrom == null || curTo == null) {
        ExchangeProviderLogger.logError(
          provider: description,
          function: 'createTrade',
          error: TradeNotCreatedException(description),
          stackTrace: StackTrace.current,
          requestData: {
            'from': request.fromCurrency.title,
            'to': request.toCurrency.title,
            'fromAmount': request.fromAmount,
            'toAmount': request.toAmount,
            'toAddress': request.toAddress,
            'refundAddress': request.refundAddress,
            'isFixedRateMode': isFixedRateMode,
            'isSendAll': isSendAll,
            'curFrom': curFrom,
            'curTo': curTo,
          },
        );
        throw TradeNotCreatedException(description);
      }

      final pairId = curFrom + '_' + curTo;

      final payload = {
        'fromAmount': request.fromAmount,
        'fromAddress': request.refundAddress,
        'toAmount': request.toAmount,
        'toAddress': request.toAddress,
        'pairId': pairId,
      };

      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        headers: _headers,
        body: json.encode(payload),
      );

      if (response.statusCode != 201) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON['error'] ?? 'Unknown error';
        final message = responseJSON['message'] ?? '';
        
        ExchangeProviderLogger.logError(
          provider: description,
          function: 'createTrade',
          error: Exception('$error\n$message'),
          stackTrace: StackTrace.current,
          requestData: {
            'from': request.fromCurrency.title,
            'to': request.toCurrency.title,
            'fromAmount': request.fromAmount,
            'toAmount': request.toAmount,
            'toAddress': request.toAddress,
            'refundAddress': request.refundAddress,
            'isFixedRateMode': isFixedRateMode,
            'isSendAll': isSendAll,
            'payload': payload,
            'url': uri.toString(),
          },
        );
        
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
      final depositAmount = _toDouble(amount['value']);
      final receiveAmount = toAmount['value'] as String;
      final status = responseJSON['status'] as String;
      final createdAtString = responseJSON['createdAt'] as String;
      final extraId = responseJSON['payInAddressTag'] as String?;

      final createdAt = DateTime.parse(createdAtString).toLocal();

      ExchangeProviderLogger.logSuccess(
        provider: description,
        function: 'createTrade',
        requestData: {
          'from': request.fromCurrency.title,
          'to': request.toCurrency.title,
          'fromAmount': request.fromAmount,
          'toAmount': request.toAmount,
          'toAddress': request.toAddress,
          'refundAddress': request.refundAddress,
          'isFixedRateMode': isFixedRateMode,
          'isSendAll': isSendAll,
          'payload': payload,
          'url': uri.toString(),
        },
        responseData: {
          'orderId': orderId,
          'depositAddress': depositAddress,
          'payoutAddress': payoutAddress,
          'refundAddress': refundAddress,
          'depositAmount': depositAmount,
          'receiveAmount': receiveAmount,
          'status': status,
          'createdAt': createdAtString,
          'extraId': extraId,
          'statusCode': response.statusCode,
          'responseJSON': responseJSON,
        },
      );

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
        userCurrencyFromRaw: '${request.fromCurrency.title}_${request.fromCurrency.tag ?? ''}',
        userCurrencyToRaw: '${request.toCurrency.title}_${request.toCurrency.tag ?? ''}',
        isSendAll: isSendAll,
      );
    } catch (e, s) {
      ExchangeProviderLogger.logError(
        provider: description,
        function: 'createTrade',
        error: e,
        stackTrace: s,
        requestData: {
          'from': request.fromCurrency.title,
          'to': request.toCurrency.title,
          'fromAmount': request.fromAmount,
          'toAmount': request.toAmount,
          'toAddress': request.toAddress,
          'refundAddress': request.refundAddress,
          'isFixedRateMode': isFixedRateMode,
          'isSendAll': isSendAll,
        },
      );
      printV(e.toString());
      throw TradeNotCreatedException(description);
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    try {
      final uri = Uri.https(_apiAuthority, '$_apiPath$_orders/$id');
      final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
      
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
      final fromAsset = pairParts.isNotEmpty ? pairParts[0] : '';
      final toAsset = pairParts.length > 1 ? pairParts[1] : '';
      final fromCurrency = CryptoCurrency.safeParseCurrencyFromString(fromAsset);
      final toCurrency = CryptoCurrency.safeParseCurrencyFromString(toAsset);

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
        userCurrencyFromRaw: '$fromAsset' + '_',
        userCurrencyToRaw: '$toAsset' + '_',
      );
    } catch (e) {
      printV(e.toString());
      throw TradeNotCreatedException(description);
    }
  }

  double _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      return 0.0;
    }
  }
}
