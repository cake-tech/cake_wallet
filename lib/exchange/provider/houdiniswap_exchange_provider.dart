import 'dart:convert';

import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_not_created_exception.dart';
import 'package:cake_wallet/exchange/trade_not_found_exception.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/utils/currency_pairs_utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';

import 'exchange_provider.dart';

abstract class HoudiniSwap extends ExchangeProvider {
  HoudiniSwap() : super(pairList: supportedPairs(_notSupported));

  static const List<CryptoCurrency> _notSupported = [];

  bool get defaultCexOnly;

  static final apiKey = '68adbcbc19908a02a9909c82:rqQoU2JAL7xfuPfqHSerim';
  static const _apiAuthority = 'api-partner.houdiniswap.com';
  static const _tokens = '/tokens';
  static const _getMinMax = '/getMinMax';
  static const _quote = '/quote';
  static const _exchange = '/exchange';
  static const _status = '/status';

  static final _headers = {'Content-Type': 'application/json', 'authorization': apiKey};

  @override
  String get title => 'HoudiniSwap';

  @override
  bool get supportsFixedRate => false;

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  static final List<HoudiniToken> tokensCache = [];

  @override
  Future<bool> checkIsAvailable() async => true;

  Future<List<HoudiniToken>> _getTokens() async {
    if (tokensCache.isNotEmpty) return tokensCache;

    final uri = Uri.https(_apiAuthority, _tokens);
    final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

    if (response.statusCode != 200) return [];

    final decoded = jsonDecode(response.body) as List<dynamic>;
    final tokens =
        decoded.map((e) => HoudiniToken.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    tokensCache.clear();
    tokensCache.addAll(tokens);
    return tokensCache;
  }

  @override
  Future<Limits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode,
      bool anonymous = false}) async {
    try {
      final tokens = await _getTokens();
      if (tokens.isEmpty) throw Exception('Failed to fetch tokens');

      final fromToken = HoudiniToken.matchHoudiniToken(from, tokens);

      final toToken = HoudiniToken.matchHoudiniToken(to, tokens);
      final params = {
        'from': fromToken.id,
        'to': toToken.id,
        'anonymous': anonymous.toString(),
        'cexOnly': defaultCexOnly.toString(),
      };

      final uri = Uri.https(_apiAuthority, _getMinMax, params);
      final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

      if (response.statusCode != 200) {
        throw Exception('Unexpected http status: ${response.statusCode}');
      }

      final result = json.decode(response.body) as List<dynamic>;

      if (result.isEmpty || result.length != 2) throw Exception('Result is empty or invalid');

      final min = _toDouble(result[0]);
      final max = _toDouble(result[1]);
      return Limits(min: min, max: max);
    } catch (e) {
      printV(e.toString());
      rethrow;
    }
  }

  Future<double> fetchRate(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required double amount,
      required bool isFixedRateMode,
      required bool isReceiveAmount,
      bool anonymous = false,
      bool useXmr = false}) async {
    try {
      final params = {
        'amount': amount.toString(),
        'from': from.title,
        'to': to.title,
        'anonymous': anonymous.toString(),
        'useXmr': useXmr.toString(),
      };

      final uri = Uri.https(_apiAuthority, _quote, params);
      final responseJSON = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

      if (responseJSON.statusCode != 200) {
        throw Exception('Unexpected http status: ${responseJSON.statusCode}');
      }

      final response = json.decode(responseJSON.body) as Map<String, dynamic>;

      final amountToSend = _toDouble(response['amountIn']);
      final amountToGet = _toDouble(response['amountOut']);

      if (amountToSend == null || amountToGet == null) {
        throw Exception('Invalid response: $response');
      }

      return amountToGet / amountToSend;
    } catch (e) {
      printV(e.toString());
      return 0.0;
    }
  }

  @override
  Future<Trade> createTrade(
      {required TradeRequest request,
      required bool isFixedRateMode,
      required bool isSendAll,
      bool anonymous = false,
      bool useXmr = false}) async {
    final tz = 'UTC';
    final ua = 'Android';
    final ip = '0.0.0.0';

    final body = <String, dynamic>{
      'amount': request.fromAmount,
      'from': request.fromCurrency.title,
      'to': request.toCurrency.title,
      'addressTo': request.toAddress,
      'anonymous': anonymous,
      'ip': ip,
      'userAgent': ua,
      'timezone': tz,
      'useXmr': useXmr
    };

    final uri = Uri.https(_apiAuthority, _exchange);

    try {
      final response =
          await ProxyWrapper().post(clearnetUri: uri, headers: _headers, body: json.encode(body));

      if (response.statusCode != 200) {
        throw Exception('Unexpected http status: ${response.statusCode}, body: ${response.body}');
      }

      final responseJSON = json.decode(response.body) as Map<String, dynamic>;

      final id = responseJSON['houdiniId'] as String? ?? '';
      final createdAtString = responseJSON['created'] as String? ?? '';
      final expireAtString = responseJSON['expires'] as String? ?? '';
      final statusRaw = responseJSON['status'] as int?;
      final inAmount = _toDouble(responseJSON['inAmount']);
      final outAmount = _toDouble(responseJSON['outAmount']);
      final inSymbol = responseJSON['inSymbol'] as String? ?? '';
      final outSymbol = responseJSON['outSymbol'] as String? ?? '';
      final senderAddress = responseJSON['senderAddress'] as String? ?? '';
      final receiverAddress = responseJSON['receiverAddress'] as String? ?? '';
      final extraId = responseJSON['senderTag'] as String?;

      final createdAt = DateTime.parse(createdAtString).toLocal();
      final expiredAt = DateTime.parse(expireAtString).toLocal();

      final fromCurrency = CryptoCurrency.safeParseCurrencyFromString(inSymbol);
      final toCurrency = CryptoCurrency.safeParseCurrencyFromString(outSymbol);

      return Trade(
        id: id,
        from: fromCurrency,
        to: toCurrency,
        provider: description,
        inputAddress: senderAddress,
        payoutAddress: receiverAddress,
        amount: inAmount.toString(),
        receiveAmount: outAmount.toString(),
        state: _normalizeHoudiniSwapState(statusRaw),
        createdAt: createdAt,
        expiredAt: expiredAt,
        extraId: extraId,
        userCurrencyFromRaw: '${request.fromCurrency.title}_${request.fromCurrency.tag ?? ''}',
        userCurrencyToRaw: '${request.toCurrency.title}_${request.toCurrency.tag ?? ''}',
      );
    } catch (e) {
      printV('CreateTrade error: $e');
      throw TradeNotCreatedException(description);
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final uri = Uri.https(_apiAuthority, _status, {'id': id});
    final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

    if (response.statusCode == 404) throw TradeNotFoundException(id, provider: description);

    if (response.statusCode != 200)
      throw Exception('Unexpected http status: ${response.statusCode}');

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    final houdiniId = responseJSON['houdiniId'] as String? ?? '';
    final createdAtString = responseJSON['created'] as String? ?? '';
    final expireAtString = responseJSON['expires'] as String? ?? '';
    final statusRaw = responseJSON['status'] as int?;
    final inAmount = _toDouble(responseJSON['inAmount']);
    final outAmount = _toDouble(responseJSON['outAmount']);

    final inSymbol = responseJSON['inSymbol'] as String? ?? '';
    final outSymbol = responseJSON['outSymbol'] as String? ?? '';

    final senderAddress = responseJSON['senderAddress'] as String? ?? '';
    final receiverAddress = responseJSON['receiverAddress'] as String? ?? '';

    final extraId = responseJSON['senderTag'] as String?;

    final outToken = responseJSON['outToken'] as Map<String, dynamic>? ?? {};
    final outTokenSymbol = outToken['symbol'] as String?;
    final outTokenNetwork = outToken['network'] as Map<String, dynamic>?;

    final inToken = responseJSON['inToken'] as Map<String, dynamic>? ?? {};
    final inTokenSymbol = inToken['symbol'] as String?;
    final inTokenNetwork = inToken['network'] as Map<String, dynamic>?;

    final outTokenNetworkShortName = outTokenNetwork?['shortName'] as String?;
    final inTokenNetworkShortName = inTokenNetwork?['shortName'] as String?;

    final createdAt = DateTime.parse(createdAtString).toLocal();
    final expiredAt = DateTime.parse(expireAtString).toLocal();

    final fromCurrency = CryptoCurrency.safeParseCurrencyFromString(inTokenSymbol ?? inSymbol);
    final toCurrency = CryptoCurrency.safeParseCurrencyFromString(outTokenSymbol ?? outSymbol);

    return Trade(
      id: houdiniId,
      from: fromCurrency,
      to: toCurrency,
      provider: description,
      inputAddress: senderAddress,
      payoutAddress: receiverAddress,
      amount: inAmount.toString(),
      receiveAmount: outAmount.toString(),
      state: _normalizeHoudiniSwapState(statusRaw),
      createdAt: createdAt,
      expiredAt: expiredAt,
      extraId: extraId,
      userCurrencyFromRaw: '${inTokenSymbol ?? inSymbol}_${inTokenNetworkShortName ?? ''}',
      userCurrencyToRaw: '${outTokenSymbol ?? outSymbol}_${outTokenNetworkShortName ?? ''}',
    );
  }

  static TradeState _normalizeHoudiniSwapState(int? raw) {
    return switch (raw) {
      -1 => TradeState.unpaid,
      0 => TradeState.wait,
      1 => TradeState.confirming,
      2 => TradeState.exchanging,
      3 => TradeState.anonymizing,
      4 => TradeState.finished,
      5 => TradeState.expired,
      6 => TradeState.failed,
      7 => TradeState.refunded,
      8 => TradeState.deleted,
      _ => TradeState.notFound,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

class HoudiniSwapCEXProvider extends HoudiniSwap {
  HoudiniSwapCEXProvider() : super();

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.houdiniCex;

  @override
  bool get defaultCexOnly => true;
}

class HoudiniToken {
  HoudiniToken({required this.id, required this.symbol, required this.name, required this.network});

  final String id;
  final String symbol;
  final String name;
  final String network;

  factory HoudiniToken.fromJson(Map<String, dynamic> json) {
    final network = json['network'] as Map<String, dynamic>;
    return HoudiniToken(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      network: network['shortName'] as String? ?? '',
    );
  }

  static HoudiniToken matchHoudiniToken(CryptoCurrency currency, List<HoudiniToken> tokens) {
    final symbol = currency.title.toUpperCase();
    final network = (currency.tag ?? currency.title).toUpperCase();

    HoudiniToken? result;

    for (final token in tokens) {
      final tokenSymbol = token.symbol.toUpperCase();
      final tokenNetwork = token.network.toUpperCase();

      if (tokenSymbol == symbol) {
        if (currency.tag != null && tokenNetwork == network) {
          return token;
        }
        result ??= token;
      }
    }

    if (result != null) return result;

    throw Exception('Token not found for ${currency.title} (${currency.tag ?? 'no tag'})');
  }

  @override
  String toString() => 'HoudiniToken{id: $id, symbol: $symbol, name: $name, network: $network}';
}
