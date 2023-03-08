import 'dart:convert';
import 'package:cake_wallet/exchange/trade_not_found_exeption.dart';
import 'package:http/http.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/changenow/changenow_request.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';

class ChangeNowExchangeProvider extends ExchangeProvider {
  ChangeNowExchangeProvider()
      : _lastUsedRateId = '',
        super(
            pairList: CryptoCurrency.all
                .where((i) => i != CryptoCurrency.xhv)
                .map((i) => CryptoCurrency.all
                    .where((i) => i != CryptoCurrency.xhv)
                    .map((k) => ExchangePair(from: i, to: k, reverse: true)))
                .expand((i) => i)
                .toList());

  static const apiKey = secrets.changeNowApiKey;
  static const apiAuthority = 'api.changenow.io';
  static const createTradePath = '/v2/exchange';
  static const findTradeByIdPath = '/v2/exchange/by-id';
  static const estimatedAmountPath = '/v2/exchange/estimated-amount';
  static const rangePath = '/v2/exchange/range';
  static const apiHeaderKey = 'x-changenow-api-key';

  @override
  String get title => 'ChangeNOW';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.changeNow;

  @override
  Future<bool> checkIsAvailable() async => true;

  String _lastUsedRateId;

  static String getFlow(bool isFixedRate) => isFixedRate ? 'fixed-rate' : 'standard';

  @override
  Future<Limits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode}) async {
    final headers = {apiHeaderKey: apiKey};
    final normalizedFrom = normalizeCryptoCurrency(from);
    final normalizedTo = normalizeCryptoCurrency(to);
    final flow = getFlow(isFixedRateMode);
    final params = <String, String>{
      'fromCurrency': normalizedFrom,
      'toCurrency': normalizedTo,
      'fromNetwork': networkFor(from),
      'toNetwork': networkFor(to),
      'flow': flow};
    final uri = Uri.https(apiAuthority, rangePath, params);
    final response = await get(uri, headers: headers);
    
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
    return Limits(
      min: responseJSON['minAmount'] as double?,
      max: responseJSON['maxAmount'] as double?);
  }

  @override
  Future<Trade> createTrade({required TradeRequest request, required bool isFixedRateMode}) async {
    final _request = request as ChangeNowRequest;
    final headers = {
      apiHeaderKey: apiKey,
      'Content-Type': 'application/json'};
    final flow = getFlow(isFixedRateMode);
    final type = isFixedRateMode ? 'reverse' : 'direct';
    final body = <String, String>{
      'fromCurrency': normalizeCryptoCurrency(_request.from),
      'toCurrency': normalizeCryptoCurrency(_request.to),
      'fromNetwork': networkFor(_request.from),
      'toNetwork': networkFor(_request.to),
      if (!isFixedRateMode) 'fromAmount': _request.fromAmount,
      if (isFixedRateMode) 'toAmount': _request.toAmount,
      'address': _request.address,
      'flow': flow,
      'type': type,
      'refundAddress': _request.refundAddress
    };

    if (isFixedRateMode) {
      // since we schedule to calculate the rate every 5 seconds we need to ensure that
      // we have the latest rate id with the given inputs before creating the trade
      await fetchRate(
        from: _request.from,
        to: _request.to,
        amount: double.tryParse(_request.toAmount) ?? 0,
        isFixedRateMode: true,
        isReceiveAmount: true,
      );
      body['rateId'] = _lastUsedRateId;
    }

    final uri = Uri.https(apiAuthority, createTradePath);
    final response = await post(uri, headers: headers, body: json.encode(body));

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
    final id = responseJSON['id'] as String;
    final inputAddress = responseJSON['payinAddress'] as String;
    final refundAddress = responseJSON['refundAddress'] as String;
    final extraId = responseJSON['payinExtraId'] as String?;
    final payoutAddress = responseJSON['payoutAddress'] as String;

    return Trade(
        id: id,
        from: _request.from,
        to: _request.to,
        provider: description,
        inputAddress: inputAddress,
        refundAddress: refundAddress,
        extraId: extraId,
        createdAt: DateTime.now(),
        amount: responseJSON['fromAmount']?.toString() ?? _request.fromAmount,
        state: TradeState.created,
        payoutAddress: payoutAddress);
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final headers = {apiHeaderKey: apiKey};
    final params = <String, String>{'id': id};
    final uri = Uri.https(apiAuthority,findTradeByIdPath, params);
    final response = await get(uri, headers: headers);

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
    final fromCurrency = responseJSON['fromCurrency'] as String;
    final from = CryptoCurrency.fromString(fromCurrency);
    final toCurrency = responseJSON['toCurrency'] as String;
    final to = CryptoCurrency.fromString(toCurrency);
    final inputAddress = responseJSON['payinAddress'] as String;
    final expectedSendAmount = responseJSON['expectedAmountFrom'].toString();
    final status = responseJSON['status'] as String;
    final state = TradeState.deserialize(raw: status);
    final extraId = responseJSON['payinExtraId'] as String;
    final outputTransaction = responseJSON['payoutHash'] as String;
    final expiredAtRaw = responseJSON['validUntil'] as String;
    final payoutAddress = responseJSON['payoutAddress'] as String;
    final expiredAt = DateTime.tryParse(expiredAtRaw)?.toLocal();

    return Trade(
        id: id,
        from: from,
        to: to,
        provider: description,
        inputAddress: inputAddress,
        amount: expectedSendAmount,
        state: state,
        extraId: extraId,
        expiredAt: expiredAt,
        outputTransaction: outputTransaction,
        payoutAddress: payoutAddress);
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

      final headers = {apiHeaderKey: apiKey};
      final isReverse = isReceiveAmount;
      final type = isReverse ? 'reverse' : 'direct';
      final flow = getFlow(isFixedRateMode);
      final params = <String, String>{
        'fromCurrency': normalizeCryptoCurrency(from),
        'toCurrency': normalizeCryptoCurrency(to),
        'fromNetwork': networkFor(from),
        'toNetwork': networkFor(to),
        'type': type,
        'flow': flow};

      if (isReverse) {
        params['toAmount'] = amount.toString();
      } else {
        params['fromAmount'] = amount.toString();
      }
      
      final uri = Uri.https(apiAuthority, estimatedAmountPath, params);
      final response = await get(uri, headers: headers);
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final fromAmount = double.parse(responseJSON['fromAmount'].toString());
      final toAmount =  double.parse(responseJSON['toAmount'].toString());
      final rateId = responseJSON['rateId'] as String? ?? '';

      if (rateId.isNotEmpty) {
        _lastUsedRateId = rateId;
      }

      return isReverse ? (amount / fromAmount) : (toAmount / amount);
    } catch(e) {
      print(e.toString());
      return 0.0;
    }
  }
 
  String networkFor(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.usdt:
        return CryptoCurrency.btc.title.toLowerCase();
      default:
        return currency.tag != null
            ? currency.tag!.toLowerCase()
            : currency.title.toLowerCase();
      }
    }

  }

   String normalizeCryptoCurrency(CryptoCurrency currency) {
   switch(currency) {
      case CryptoCurrency.zec:
        return 'zec';
      case CryptoCurrency.usdcpoly:
        return 'usdcmatic';
      case CryptoCurrency.maticpoly:
        return 'maticmainnet';
      default:
        return currency.title.toLowerCase();
    }

  }
