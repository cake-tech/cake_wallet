import 'dart:convert';

import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/sideshift/sideshift_request.dart';
import 'package:cake_wallet/exchange/trade_not_created_exeption.dart';
import 'package:cake_wallet/exchange/trade_not_found_exeption.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:http/http.dart';

class SideShiftExchangeProvider extends ExchangeProvider {
  SideShiftExchangeProvider() : super(pairList: _supportedPairs());

  static const affiliateId = secrets.sideShiftAffiliateId;
  static const apiBaseUrl = 'https://sideshift.ai/api';
  static const rangePath = '/v2/pair';
  static const orderPath = '/v2/shifts';
  static const quotePath = '/v2/quotes';
  static const permissionPath = '/v2/permissions';

  static const List<CryptoCurrency> _notSupported = [
    CryptoCurrency.xhv,
    CryptoCurrency.dcr,
    CryptoCurrency.kmd,
    CryptoCurrency.oxt,
    CryptoCurrency.pivx,
    CryptoCurrency.rune,
    CryptoCurrency.rvn,
    CryptoCurrency.scrt,
    CryptoCurrency.stx,
    CryptoCurrency.bttc,
    CryptoCurrency.usdt,
    CryptoCurrency.eos,
  ];

  static List<ExchangePair> _supportedPairs() {
    final supportedCurrencies =
        CryptoCurrency.all.where((element) => !_notSupported.contains(element)).toList();

    return supportedCurrencies
        .map((i) => supportedCurrencies.map((k) => ExchangePair(from: i, to: k, reverse: true)))
        .expand((i) => i)
        .toList();
  }

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.sideShift;

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

      final fromCurrency = from.title.toLowerCase();
      final toCurrency = to.title.toLowerCase();
      final depositNetwork = _networkFor(from);
      final settleNetwork = _networkFor(to);

      final url = "$apiBaseUrl$rangePath/$fromCurrency-$depositNetwork/$toCurrency-$settleNetwork?amount=$amount";

      final uri = Uri.parse(url);
      final response = await get(uri);
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final rate = double.parse(responseJSON['rate'] as String);

      return rate;
    } catch (_) {
      return 0.00;
    }
  }

  @override
  Future<bool> checkIsAvailable() async {
    const url = apiBaseUrl + permissionPath;
    final uri = Uri.parse(url);
    final response = await get(uri);

    if (response.statusCode == 500) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['error']['message'] as String;

      throw Exception('$error');
    }

    if (response.statusCode != 200) {
      return false;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final cancreateShift = responseJSON['createShift'] as bool;
    return cancreateShift;
  }

  @override
  Future<Trade> createTrade({required TradeRequest request, required bool isFixedRateMode}) async {
    final _request = request as SideShiftRequest;
    String url = '';
    final depositCoin = request.depositMethod.title.toLowerCase();
    final settleCoin = request.settleMethod.title.toLowerCase();
    final body = {
      'affiliateId': affiliateId,
      'settleAddress': _request.settleAddress,
      'refundAddress': _request.refundAddress,
    };

    if (isFixedRateMode) {
      final quoteId = await _createQuote(_request);
      body['quoteId'] = quoteId;

      url = apiBaseUrl + orderPath + '/fixed';
    } else {
      url = apiBaseUrl + orderPath + '/variable';
      final depositNetwork = _networkFor(request.depositMethod);
      final settleNetwork = _networkFor(request.settleMethod);
      body["depositCoin"] = depositCoin;
      body["settleCoin"] = settleCoin;
      body["settleNetwork"] = settleNetwork;
      body["depositNetwork"] = depositNetwork;
    }
    final headers = {'Content-Type': 'application/json'};

    final uri = Uri.parse(url);
    final response = await post(uri, headers: headers, body: json.encode(body));

    if (response.statusCode != 201) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON['error']['message'] as String;

        throw TradeNotCreatedException(description, description: error);
      }

      throw TradeNotCreatedException(description);
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final id = responseJSON['id'] as String;
    final inputAddress = responseJSON['depositAddress'] as String;
    final settleAddress = responseJSON['settleAddress'] as String;
    final depositAmount = responseJSON['depositAmount'] as String?;

    return Trade(
      id: id,
      provider: description,
      from: _request.depositMethod,
      to: _request.settleMethod,
      inputAddress: inputAddress,
      refundAddress: settleAddress,
      state: TradeState.created,
      amount: depositAmount ?? _request.depositAmount,
      payoutAddress: settleAddress,
      createdAt: DateTime.now(),
    );
  }

  Future<String> _createQuote(SideShiftRequest request) async {
    final url = apiBaseUrl + quotePath;
    final headers = {'Content-Type': 'application/json'};
    final depositMethod = request.depositMethod.title.toLowerCase();
    final settleMethod = request.settleMethod.title.toLowerCase();
    final depositNetwork = _networkFor(request.depositMethod);
    final settleNetwork = _networkFor(request.settleMethod);
    final body = {
      'depositCoin': depositMethod,
      'settleCoin': settleMethod,
      'affiliateId': affiliateId,
      'settleAmount': request.depositAmount,
      'settleNetwork': settleNetwork,
      'depositNetwork': depositNetwork,
    };
    final uri = Uri.parse(url);
    final response = await post(uri, headers: headers, body: json.encode(body));

    if (response.statusCode != 201) {
      if (response.statusCode == 400) {
        final responseJSON = json.decode(response.body) as Map<String, dynamic>;
        final error = responseJSON['error']['message'] as String;

        throw TradeNotCreatedException(description, description: error);
      }

      throw TradeNotCreatedException(description);
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final quoteId = responseJSON['id'] as String;

    return quoteId;
  }

  @override
  Future<Limits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode}) async {
    final fromCurrency = isFixedRateMode ? to : from;
    final toCurrency = isFixedRateMode ? from : to;

    final fromNetwork = _networkFor(fromCurrency);
    final toNetwork = _networkFor(toCurrency);

    final url =
        "$apiBaseUrl$rangePath/${fromCurrency.title.toLowerCase()}-$fromNetwork/${toCurrency.title.toLowerCase()}-$toNetwork";

    final uri = Uri.parse(url);
    final response = await get(uri);

    if (response.statusCode == 500) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['error']['message'] as String;

      throw Exception('$error');
    }

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final min = double.tryParse(responseJSON['min'] as String? ?? '');
    final max = double.tryParse(responseJSON['max'] as String? ?? '');

    if (isFixedRateMode) {
      final currentRate = double.parse(responseJSON['rate'] as String);
      return Limits(
        min: min != null ? (min * currentRate) : null,
        max: max != null ? (max * currentRate) : null,
      );
    }

    return Limits(min: min, max: max);
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final url = apiBaseUrl + orderPath + '/' + id;
    final uri = Uri.parse(url);
    final response = await get(uri);

    if (response.statusCode == 404) {
      throw TradeNotFoundException(id, provider: description);
    }

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = responseJSON['error']['message'] as String;

      throw TradeNotFoundException(id, provider: description, description: error);
    }

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final fromCurrency = responseJSON['depositCoin'] as String;
    final from = CryptoCurrency.fromString(fromCurrency);
    final toCurrency = responseJSON['settleCoin'] as String;
    final to = CryptoCurrency.fromString(toCurrency);
    final inputAddress = responseJSON['depositAddress'] as String;
    final expectedSendAmount = responseJSON['depositAmount'] as String?;
    final status = responseJSON['status'] as String?;
    final settleAddress = responseJSON['settleAddress'] as String;
    TradeState? state;

    state = TradeState.deserialize(raw: status ?? 'created');
    final isVariable = (responseJSON['type'] as String) == 'variable';

    final expiredAtRaw = responseJSON['expiresAt'] as String;
    final expiredAt = isVariable ? null : DateTime.tryParse(expiredAtRaw)?.toLocal();

    return Trade(
        id: id,
        from: from,
        to: to,
        provider: description,
        inputAddress: inputAddress,
        amount: expectedSendAmount ?? '',
        state: state,
        expiredAt: expiredAt,
        payoutAddress: settleAddress);
  }

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  String get title => 'SideShift';

  String _networkFor(CryptoCurrency currency) =>
      currency.tag != null ? _normalizeTag(currency.tag!) : 'mainnet';

  String _normalizeTag(String tag) {
    switch (tag) {
      case 'ETH':
        return 'ethereum';
      case 'TRX':
        return 'tron';
      case 'LN':
        return 'lightning';
      case 'POLY':
        return 'polygon';
      case 'ZEC':
        return 'zcash';
      case 'AVAXC':
        return 'avax';
      default:
        return tag.toLowerCase();
    }
  }
}
