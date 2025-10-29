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
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cake_wallet/utils/exchange_provider_logger.dart';

class LetsExchangeExchangeProvider extends ExchangeProvider {
  LetsExchangeExchangeProvider() : super(pairList: supportedPairs(_notSupported));

  static const List<CryptoCurrency> _notSupported = [];

  static const apiKey = secrets.letsExchangeBearerToken;
  static const _baseUrl = 'api.letsexchange.io';
  static const _infoPath = '/api/v1/info';
  static const _infoRevertPath = '/api/v1/info-revert';
  static const _createTransactionPath = '/api/v1/transaction';
  static const _createTransactionRevertPath = '/api/v1/transaction-revert';
  static const _getTransactionPath = '/api/v1/transaction';

  static const _affiliateId = secrets.letsExchangeAffiliateId;

  @override
  String get title => 'LetsExchange';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.letsExchange;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Limits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode}) async {
    final networkFrom = _getNetworkType(from);
    final networkTo = _getNetworkType(to);

    try {
      final params = {
        'from': from.title,
        'to': to.title,
        if (networkFrom != null) 'network_from': networkFrom,
        if (networkTo != null) 'network_to': networkTo,
        'amount': '1',
        'affiliate_id': _affiliateId,
        'float': isFixedRateMode ? 'false' : 'true',
      };

      final responseJSON = await _getInfo(params, isFixedRateMode);
      final min = double.tryParse(responseJSON['min_amount'] as String);
      final max = double.tryParse(responseJSON['max_amount'] as String);
      return Limits(min: min, max: max);
    } catch (e) {
      log(e.toString());
      throw Exception('Failed to fetch limits');
    }
  }

  @override
  Future<double> fetchRate({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required double amount,
    required bool isFixedRateMode,
    required bool isReceiveAmount
  }) async {
    final networkFrom = _getNetworkType(from);
    final networkTo = _getNetworkType(to);
    try {
      final params = {
        'from': from.title,
        'to': to.title,
        if (networkFrom != null) 'network_from': networkFrom,
        if (networkTo != null) 'network_to': networkTo,
        'amount': amount.toString(),
        'affiliate_id': _affiliateId,
        'float': isFixedRateMode ? 'false' : 'true',
      };

      final responseJSON = await _getInfo(params, isFixedRateMode);

      final amountToGet = double.tryParse(responseJSON['amount'] as String) ?? 0.0;

      if (amountToGet == 0.0) return 0.0;

      final rate = isFixedRateMode ? amount / amountToGet : amountToGet / amount;

      ExchangeProviderLogger.logSuccess(
        provider: description,
        function: 'fetchRate',
        requestData: {
          'from': from.title,
          'to': to.title,
          'amount': amount,
          'isFixedRateMode': isFixedRateMode,
          'isReceiveAmount': isReceiveAmount,
          'networkFrom': networkFrom,
          'networkTo': networkTo,
          'params': params,
        },
        responseData: {
          'amountToGet': amountToGet,
          'rate': rate,
          'responseJSON': responseJSON,
        },
      );

      return rate;
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
          'networkFrom': networkFrom,
          'networkTo': networkTo,
        },
      );
      printV(e.toString());
      return 0.0;
    }
  }

  @override
  Future<Trade> createTrade(
      {required TradeRequest request,
      required bool isFixedRateMode,
      required bool isSendAll}) async {
    final networkFrom = _getNetworkType(request.fromCurrency);
    final networkTo = _getNetworkType(request.toCurrency);
    try {
      final params = {
        'from': request.fromCurrency.title,
        'to': request.toCurrency.title,
        if (networkFrom != null) 'network_from': networkFrom,
        if (networkTo != null) 'network_to': networkTo,
        'amount': isFixedRateMode ? request.toAmount.toString() : request.fromAmount.toString(),
        'affiliate_id': _affiliateId,
        'float': isFixedRateMode ? 'false' : 'true',
      };

      final responseInfoJSON = await _getInfo(params, isFixedRateMode);
      final rateId = responseInfoJSON['rate_id'] as String;

      final withdrawalAddress = _normalizeBchAddress(request.toAddress);
      final returnAddress = _normalizeBchAddress(request.refundAddress);

      final tradeParams = {
        'coin_from': request.fromCurrency.title,
        'coin_to': request.toCurrency.title,
        if (!isFixedRateMode) 'deposit_amount': request.fromAmount.toString(),
        'withdrawal': withdrawalAddress,
        if (isFixedRateMode) 'withdrawal_amount': request.toAmount.toString(),
        'withdrawal_extra_id': '',
        'return': returnAddress,
        'rate_id': rateId,
        if (networkFrom != null) 'network_from': networkFrom,
        if (networkTo != null) 'network_to': networkTo,
        'affiliate_id': _affiliateId,
        'float': isFixedRateMode ? 'false' : 'true',
      };

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': apiKey
      };

      final uri = Uri.https(_baseUrl,
          isFixedRateMode ? _createTransactionRevertPath : _createTransactionPath);
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        headers: headers,
        body: json.encode(tradeParams),
      );
      

      if (response.statusCode != 200) {
        ExchangeProviderLogger.logError(
          provider: description,
          function: 'createTrade',
          error: Exception('LetsExchange create trade failed: ${response.body}'),
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
            'networkFrom': networkFrom,
            'networkTo': networkTo,
            'tradeParams': tradeParams,
            'url': uri.toString(),
          },
        );
        throw Exception('LetsExchange create trade failed: ${response.body}');
      }
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final id = responseJSON['transaction_id'] as String;
      final from = responseJSON['coin_from'] as String;
      final to = responseJSON['coin_to'] as String;
      final payoutAddress = responseJSON['withdrawal'] as String;
      final depositAddress = responseJSON['deposit'] as String;
      final refundAddress = responseJSON['return'] as String;
      final depositAmount = responseJSON['deposit_amount'] as String;
      final receiveAmount = responseJSON['withdrawal_amount'] as String;
      final status = responseJSON['status'] as String;
      final createdAtString = responseJSON['created_at'] as String;
      final expiredAtTimestamp = responseJSON['expired_at'] as int;
      final extraId = responseJSON['deposit_extra_id'] as String?;

      final createdAt = DateTime.parse(createdAtString).toLocal();
      final expiredAt = DateTime.fromMillisecondsSinceEpoch(expiredAtTimestamp * 1000).toLocal();

      CryptoCurrency fromCurrency;
      if (request.fromCurrency.tag != null && request.fromCurrency.title == from) {
        fromCurrency = request.fromCurrency;
      } else {
        fromCurrency = CryptoCurrency.fromString(from);
      }

      CryptoCurrency toCurrency;
      if (request.toCurrency.tag != null && request.toCurrency.title == to) {
        toCurrency = request.toCurrency;
      } else {
        toCurrency = CryptoCurrency.fromString(to);
      }

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
          'networkFrom': networkFrom,
          'networkTo': networkTo,
          'tradeParams': tradeParams,
          'url': uri.toString(),
        },
        responseData: {
          'id': id,
          'from': from,
          'to': to,
          'depositAddress': depositAddress,
          'payoutAddress': payoutAddress,
          'refundAddress': refundAddress,
          'depositAmount': depositAmount,
          'receiveAmount': receiveAmount,
          'status': status,
          'createdAt': createdAtString,
          'expiredAt': expiredAtTimestamp,
          'extraId': extraId,
          'statusCode': response.statusCode,
        },
      );

      return Trade(
        id: id,
        from: fromCurrency,
        to: toCurrency,
        provider: description,
        inputAddress: depositAddress,
        payoutAddress: payoutAddress,
        refundAddress: refundAddress,
        amount: depositAmount,
        receiveAmount: receiveAmount,
        state: TradeState.deserialize(raw: status),
        createdAt: createdAt,
        expiredAt: expiredAt,
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
          'networkFrom': networkFrom,
          'networkTo': networkTo,
        },
      );
      log(e.toString());
      throw TradeNotCreatedException(description);
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': apiKey
    };

    final url = Uri.https(_baseUrl, '$_getTransactionPath/$id');
    final response = await ProxyWrapper().get(clearnetUri: url, headers: headers);
    

    if (response.statusCode != 200) {
      throw Exception('LetsExchange fetch trade failed: ${response.body}');
    }
    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final from = responseJSON['coin_from'] as String;
    final fromNetwork = responseJSON['coin_from_network'] as String?;
    final to = responseJSON['coin_to'] as String;
    final toNetwork = responseJSON['coin_to_network'] as String?;
    final payoutAddress = responseJSON['withdrawal'] as String;
    final depositAddress = responseJSON['deposit'] as String;
    final refundAddress = responseJSON['return'] as String;
    final depositAmount = responseJSON['deposit_amount'] as String;
    final receiveAmount = responseJSON['withdrawal_amount'] as String;
    final status = responseJSON['status'] as String;
    final createdAtString = responseJSON['created_at'] as String;
    final expiredAtTimestamp = responseJSON['expired_at'] as int;
    final extraId = responseJSON['deposit_extra_id'] as String?;

    final createdAt = DateTime.parse(createdAtString).toLocal();
    final expiredAt = DateTime.fromMillisecondsSinceEpoch(expiredAtTimestamp * 1000).toLocal();

    final normalizedFromNetwork = _normalizeNetworkType(fromNetwork ?? '');
    final normalizedToNetwork = _normalizeNetworkType(toNetwork ?? '');

    return Trade(
      id: id,
      from: CryptoCurrency.safeParseCurrencyFromString(from),
      to: CryptoCurrency.safeParseCurrencyFromString(to),
      provider: description,
      inputAddress: depositAddress,
      payoutAddress: payoutAddress,
      refundAddress: refundAddress,
      amount: depositAmount,
      receiveAmount: receiveAmount,
      state: TradeState.deserialize(raw: status),
      createdAt: createdAt,
      expiredAt: expiredAt,
      isRefund: status == 'refund',
      extraId: extraId,
      userCurrencyFromRaw: '$from' + '_' + normalizedFromNetwork,
      userCurrencyToRaw: '$to' + '_' + '$normalizedToNetwork',
    );
  }

  Future<Map<String, dynamic>> _getInfo(Map<String, String> params, bool isFixedRateMode) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': apiKey
    };

    try {
      final uri = Uri.https(_baseUrl, isFixedRateMode ? _infoRevertPath : _infoPath);
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        headers: headers,
        body: json.encode(params),
      );
      
      if (response.statusCode != 200) {
        throw Exception('LetsExchange fetch info failed: ${response.body}');
      }
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('LetsExchange failed to fetch info ${e.toString()}');
    }
  }

  String? _getNetworkType(CryptoCurrency currency) {
    if (currency.tag != null && currency.tag!.isNotEmpty) {
      switch (currency.tag!) {
        case 'TRX':
          return 'TRC20';
        case 'ETH':
          return 'ERC20';
        case 'BSC':
          return 'BEP20';
        default:
          return currency.tag!;
      }
    }
    return currency.title;
  }

  String _normalizeNetworkType(String network) {
    return switch (network.toUpperCase()) {
      'ERC20' => 'ETH',
      'TRC20' => 'TRX',
      'BEP20' => 'BSC',
      _ => network,
    };
  }

  String _normalizeBchAddress(String address) =>
      address.startsWith('bitcoincash:') ? address.substring(12) : address;
}
