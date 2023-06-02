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
    CryptoCurrency.mkr,
    CryptoCurrency.oxt,
    CryptoCurrency.pivx,
    CryptoCurrency.rune,
    CryptoCurrency.rvn,
    CryptoCurrency.scrt,
    CryptoCurrency.stx,
    CryptoCurrency.bttc,
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
      final fromCurrency = _normalizeCryptoCurrency(from);
      final toCurrency = _normalizeCryptoCurrency(to);
      final url = apiBaseUrl + rangePath + '/' + fromCurrency + '/' + toCurrency;
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

    return Trade(
      id: id,
      provider: description,
      from: _request.depositMethod,
      to: _request.settleMethod,
      inputAddress: inputAddress,
      refundAddress: settleAddress,
      state: TradeState.created,
      amount: _request.depositAmount,
      payoutAddress: settleAddress,
      createdAt: DateTime.now(),
    );
  }

  Future<String> _createQuote(SideShiftRequest request) async {
    final url = apiBaseUrl + quotePath;
    final headers = {'Content-Type': 'application/json'};
    final depositMethod = _normalizeCryptoCurrency(request.depositMethod);
    final settleMethod = _normalizeCryptoCurrency(request.settleMethod);
    final body = {
      'depositCoin': depositMethod,
      'settleCoin': settleMethod,
      'affiliateId': affiliateId,
      'depositAmount': request.depositAmount,
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
    final fromCurrency = _normalizeCryptoCurrency(from);
    final toCurrency = _normalizeCryptoCurrency(to);
    final url = apiBaseUrl + rangePath + '/' + fromCurrency + '/' + toCurrency;
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
    final expectedSendAmount = responseJSON['depositAmount'].toString();
    final status = responseJSON['status'] as String?;
    final settleAddress = responseJSON['settleAddress'] as String;
    TradeState? state;

    state = TradeState.deserialize(raw: status ?? 'created');

    final expiredAtRaw = responseJSON['expiresAt'] as String;
    final expiredAt = DateTime.tryParse(expiredAtRaw)?.toLocal();

    return Trade(
        id: id,
        from: from,
        to: to,
        provider: description,
        inputAddress: inputAddress,
        amount: expectedSendAmount,
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

  static String _normalizeCryptoCurrency(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.zaddr:
        return 'zaddr';
      case CryptoCurrency.zec:
        return 'zec';
      case CryptoCurrency.bnb:
        return currency.tag!.toLowerCase();
      case CryptoCurrency.usdterc20:
        return 'usdtErc20';
      case CryptoCurrency.usdttrc20:
        return 'usdtTrc20';
      case CryptoCurrency.usdcpoly:
        return 'usdcpolygon';
      case CryptoCurrency.usdcsol:
        return 'usdcsol';
      case CryptoCurrency.maticpoly:
        return 'polygon';
      case CryptoCurrency.btcln:
        return 'ln';
      default:
        return currency.title.toLowerCase();
    }
  }
}
