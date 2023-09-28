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
import 'package:cake_wallet/exchange/exolix/exolix_request.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';

class ExolixExchangeProvider extends ExchangeProvider {
  ExolixExchangeProvider() : super(pairList: _supportedPairs());

  static final apiKey = secrets.exolixApiKey;
  static const apiBaseUrl = 'exolix.com';
  static const transactionsPath = '/api/v2/transactions';
  static const ratePath = '/api/v2/rate';

  static const List<CryptoCurrency> _notSupported = [
    CryptoCurrency.usdt,
    CryptoCurrency.xhv,
    CryptoCurrency.btt,
    CryptoCurrency.firo,
    CryptoCurrency.zaddr,
    CryptoCurrency.xvg,
    CryptoCurrency.kmd,
    CryptoCurrency.paxg,
    CryptoCurrency.rune,
    CryptoCurrency.scrt,
    CryptoCurrency.btcln,
    CryptoCurrency.cro,
    CryptoCurrency.ftm,
    CryptoCurrency.frax,
    CryptoCurrency.gusd,
    CryptoCurrency.gtc,
    CryptoCurrency.weth,
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
  String get title => 'Exolix';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.exolix;

  @override
  Future<bool> checkIsAvailable() async => true;

  static String getRateType(bool isFixedRate) => isFixedRate ? 'fixed' : 'float';

  @override
  Future<Limits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode}) async {
    final params = <String, String>{
      'rateType': getRateType(isFixedRateMode),
      'amount': '1',
    };
    if (isFixedRateMode) {
      params['coinFrom'] = _normalizeCurrency(to);
      params['coinTo'] = _normalizeCurrency(from);
      params['networkFrom'] = _networkFor(to);
      params['networkTo'] = _networkFor(from);
    } else {
      params['coinFrom'] = _normalizeCurrency(from);
      params['coinTo'] = _normalizeCurrency(to);
      params['networkFrom'] = _networkFor(from);
      params['networkTo'] = _networkFor(to);
    }
    final uri = Uri.https(apiBaseUrl, ratePath, params);
    final response = await get(uri);

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    return Limits(min: responseJSON['minAmount'] as double?);
  }

  @override
  Future<Trade> createTrade({required TradeRequest request, required bool isFixedRateMode}) async {
    final _request = request as ExolixRequest;

    final headers = {'Content-Type': 'application/json'};
    final body = <String, dynamic>{
      'coinFrom': _normalizeCurrency(_request.from),
      'coinTo':  _normalizeCurrency(_request.to),
      'networkFrom': _networkFor(_request.from),
      'networkTo': _networkFor(_request.to),
      'withdrawalAddress': _request.address,
      'refundAddress': _request.refundAddress,
      'rateType': getRateType(isFixedRateMode),
      'apiToken': apiKey,
    };

    if (isFixedRateMode) {
      body['withdrawalAmount'] = _request.toAmount;
    } else {
      body['amount'] = _request.fromAmount;
    }

    final uri = Uri.https(apiBaseUrl, transactionsPath);
    final response = await post(uri, headers: headers, body: json.encode(body));

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final errors = responseJSON['errors'] as Map<String, String>;
      final errorMessage = errors.values.join(', ');
      throw Exception(errorMessage);
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final id = responseJSON['id'] as String;
    final inputAddress = responseJSON['depositAddress'] as String;
    final refundAddress = responseJSON['refundAddress'] as String?;
    final extraId = responseJSON['depositExtraId'] as String?;
    final payoutAddress = responseJSON['withdrawalAddress'] as String;
    final amount = responseJSON['amount'].toString();

    return Trade(
        id: id,
        from: _request.from,
        to: _request.to,
        provider: description,
        inputAddress: inputAddress,
        refundAddress: refundAddress,
        extraId: extraId,
        createdAt: DateTime.now(),
        amount: amount,
        state: TradeState.created,
        payoutAddress: payoutAddress);
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final findTradeByIdPath = transactionsPath + '/$id';
    final uri = Uri.https(apiBaseUrl, findTradeByIdPath);
    final response = await get(uri);

    if (response.statusCode == 404) {
      throw TradeNotFoundException(id, provider: description);
    }

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final errors = responseJSON['errors'] as Map<String, String>;
      final errorMessage = errors.values.join(', ');

      throw TradeNotFoundException(id, provider: description, description: errorMessage);
    }

    if (response.statusCode != 200) {
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final coinFrom = responseJSON['coinFrom']['coinCode'] as String;
    final from = CryptoCurrency.fromString(coinFrom);
    final coinTo = responseJSON['coinTo']['coinCode'] as String;
    final to = CryptoCurrency.fromString(coinTo);
    final inputAddress = responseJSON['depositAddress'] as String;
    final amount = responseJSON['amount'].toString();
    final status = responseJSON['status'] as String;
    final state = TradeState.deserialize(raw: _prepareStatus(status));
    final extraId = responseJSON['depositExtraId'] as String?;
    final outputTransaction = responseJSON['hashOut']['hash'] as String?;
    final payoutAddress = responseJSON['withdrawalAddress'] as String;

    return Trade(
        id: id,
        from: from,
        to: to,
        provider: description,
        inputAddress: inputAddress,
        amount: amount,
        state: state,
        extraId: extraId,
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

      final params = <String, String>{
        'coinFrom': _normalizeCurrency(from),
        'coinTo': _normalizeCurrency(to),
        'networkFrom': _networkFor(from),
        'networkTo': _networkFor(to),
        'rateType': getRateType(isFixedRateMode),
      };

      if (isReceiveAmount) {
        params['withdrawalAmount'] = amount.toString();
      } else {
        params['amount'] = amount.toString();
      }

      final uri = Uri.https(apiBaseUrl, ratePath, params);
      final response = await get(uri);
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        final message = responseJSON['message'] as String?;
        throw Exception(message);
      }

      final rate = responseJSON['rate'] as double;

      return rate;
    } catch (e) {
      print(e.toString());
      return 0.0;
    }
  }

  String _prepareStatus(String status) {
    switch (status) {
      case 'deleted':
      case 'error':
        return 'overdue';
      default:
        return status;
    }
  }

  String _networkFor(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.arb:
        return 'ARBITRUM';
      default:
        return currency.tag != null ? _normalizeTag(currency.tag!) : currency.title;
    }
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.nano:
        return 'XNO';
      case CryptoCurrency.bttc:
        return 'BTT';
      case CryptoCurrency.zec:
        return 'ZEC';
      default:
        return currency.title;
    }
  }

  String _normalizeTag(String tag) {
    switch (tag) {
      case 'POLY':
        return 'Polygon';
      default:
        return tag;
    }
  }
}
