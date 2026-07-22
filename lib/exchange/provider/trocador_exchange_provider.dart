import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cake_wallet/utils/exchange_provider_logger.dart';

class TrocadorExchangeProvider extends ExchangeProvider {
  TrocadorExchangeProvider({this.useTorOnly = false, this.providerStates = const {}})
      : _lastUsedRateId = '',
        _provider = [];

  bool useTorOnly;
  Map<String, bool> providerStates;

  static const List<String> availableProviders = [
    'Swapter',
    'StealthEx',
    'Simpleswap',
    'Swapuz',
    'ChangeNow',
    'Changehero',
    'FixedFloat',
    'LetsExchange',
    'Exolix',
    'Godex',
    'Exch',
    'CoinCraddle',
    'Alfacash',
    'LocalMonero',
    'XChange',
    'NeroSwap',
    'Changee',
    'BitcoinVN',
    'EasyBit',
    'WizardSwap',
    'Quantex',
    'SwapSpace',
  ];

  static final apiKey = isMoneroOnly ? secrets.trocadorMoneroApiKey : secrets.trocadorApiKey;
  static const clearNetAuthority = 'api.trocador.app';
  static const onionApiAuthority = clearNetAuthority;
  // static const onionApiAuthority = 'trocadorfyhlu27aefre5u7zri66gudtzdyelymftvr4yjwcxhfaqsid.onion';
  static const markup = secrets.trocadorExchangeMarkup;
  static const newRatePath = '/new_rate';
  static const createTradePath = '/new_trade';
  static const tradePath = '/trade';
  static const coinPath = '/coin';
  static const providersListPath = '/exchanges';

  String _lastUsedRateId;
  List<dynamic> _provider;

  @override
  String get title => 'Trocador';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  bool get supportsOnionAddress => true;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.trocador;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Limits?> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode}) async {
    final params = {
      'ticker': _normalizeCurrency(from),
      'name': from.name,
    };

    final uri = await _getUri(coinPath, params);
    final response = await ProxyWrapper().get(clearnetUri: uri, headers: {'API-Key': apiKey});

    if (response.statusCode != 200)
      throw Exception('Unexpected http status: ${response.statusCode}');

    final responseJSON = json.decode(response.body) as List<dynamic>;

    if (responseJSON.isEmpty) throw Exception('No data');

    final coinJson = responseJSON.first as Map<String, dynamic>;

    final min = double.tryParse(coinJson['minimum']?.toString() ?? '');
    final max = double.tryParse(coinJson['maximum']?.toString() ?? '');
    if (max == 0) return null;
    return Limits(min: min, max: max);
  }

  @override
  Future<double> fetchRate(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required double amount,
      required bool isFixedRateMode,
      required bool isReceiveAmount}) async {
    try {
      if (amount == 0) return 0.0;

      final params = <String, String>{
        'ticker_from': _normalizeCurrency(from),
        'ticker_to': _normalizeCurrency(to),
        'network_from': _networkFor(from),
        'network_to': _networkFor(to),
        if (!isFixedRateMode) 'amount_from': amount.toString(),
        if (isFixedRateMode) 'amount_to': amount.toString(),
        'payment': isFixedRateMode ? 'True' : 'False',
        'min_kycrating': 'C',
        'markup': markup,
      };

      final uri = await _getUri(newRatePath, params);
      final response = await ProxyWrapper().get(clearnetUri: uri, headers: {'API-Key': apiKey});

      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final fromAmount = double.tryParse(responseJSON['amount_from']?.toString() ?? '') ?? 0.0;
      final toAmount = double.tryParse(responseJSON['amount_to']?.toString() ?? '') ?? 0.0;

      if (fromAmount <= 0 || toAmount <= 0) return 0.0;

      final quotesData = responseJSON['quotes'];
      final rateId = _safeString(responseJSON, 'trade_id');

      if (quotesData == null || quotesData is! Map<String, dynamic>) {
        return 0.0;
      }
      final quotes = (quotesData['quotes'] as List?) ?? [];
      _provider = quotes
          .where((quote) => providerStates[quote['provider']] != false)
          .map((quote) => quote['provider'])
          .toList();

      if (_provider.isEmpty) {
        ExchangeProviderLogger.logError(
          provider: description,
          function: 'fetchRate',
          error: Exception('No enabled providers found for the selected trade.'),
          stackTrace: StackTrace.current,
          requestData: {
            'from': from.title,
            'to': to.title,
            'amount': amount,
            'isFixedRateMode': isFixedRateMode,
            'isReceiveAmount': isReceiveAmount,
            'params': params,
            'url': uri.toString(),
          },
        );
        throw Exception('No enabled providers found for the selected trade.');
      }

      if (rateId.isNotEmpty) _lastUsedRateId = rateId;

      final rate = isReceiveAmount ? (amount / fromAmount) : (toAmount / amount);

      ExchangeProviderLogger.logSuccess(
        provider: description,
        function: 'fetchRate',
        requestData: {
          'from': from.title,
          'to': to.title,
          'amount': amount,
          'isFixedRateMode': isFixedRateMode,
          'isReceiveAmount': isReceiveAmount,
          'params': params,
          'url': uri.toString(),
        },
        responseData: {
          'fromAmount': fromAmount,
          'toAmount': toAmount,
          'rate': rate,
          'rateId': rateId,
          'provider': _provider.first,
          'statusCode': response.statusCode,
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
        },
      );
      printV(e.toString());
      return 0.0;
    }
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
    required bool isFixedRateMode,
    required bool isSendAll,
  }) async {
    final params = {
      'ticker_from': _normalizeCurrency(request.fromCurrency),
      'ticker_to': _normalizeCurrency(request.toCurrency),
      'network_from': _networkFor(request.fromCurrency),
      'network_to': _networkFor(request.toCurrency),
      'payment': isFixedRateMode ? 'True' : 'False',
      'min_kycrating': 'C',
      'markup': markup,
      if (!isFixedRateMode) 'amount_from': request.fromAmount,
      if (isFixedRateMode) 'amount_to': request.toAmount,
      'address': request.toAddress,
      if (request.toAddressExtraId.isNotEmpty) 'address_memo': request.toAddressExtraId,
      'refund': request.refundAddress,
      'refund_memo': '0',
    };

    if (isFixedRateMode) {
      await fetchRate(
        from: request.fromCurrency,
        to: request.toCurrency,
        amount: double.tryParse(request.toAmount) ?? 0,
        isFixedRateMode: true,
        isReceiveAmount: true,
      );
      params['id'] = _lastUsedRateId;
    }

    if (_provider.isEmpty || _provider.first == null || _provider.first.toString().isEmpty) {
      ExchangeProviderLogger.logError(
        provider: description,
        function: 'createTrade',
        error: Exception('No available provider is enabled'),
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
          'params': params,
        },
      );
      throw Exception('No available provider is enabled');
    }

    params['provider'] = _provider.first.toString();

    final uri = await _getUri(createTradePath, params);
    final response = await ProxyWrapper().get(clearnetUri: uri, headers: {'API-Key': apiKey});

    if (response.statusCode == 400) {
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final error = _safeString(responseJSON, 'error', 'Unknown error');
      final message = _safeString(responseJSON, 'message');

      ExchangeProviderLogger.logError(
        provider: description,
        function: 'createTrade',
        error: Exception('${error}\n$message'),
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
          'params': params,
          'url': uri.toString(),
        },
      );

      throw Exception('${error}\n$message');
    }

    if (response.statusCode != 200) {
      ExchangeProviderLogger.logError(
        provider: description,
        function: 'createTrade',
        error: Exception('Unexpected http status: ${response.statusCode}'),
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
          'params': params,
          'url': uri.toString(),
        },
      );
      throw Exception('Unexpected http status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    final id = _safeString(responseJSON, 'trade_id');
    final inputAddress = _safeString(responseJSON, 'address_provider');
    final refundAddress = _safeString(responseJSON, 'refund_address');
    final status = _safeString(responseJSON, 'status');
    final payoutAddress = _safeString(responseJSON, 'address_user');
    final date = _safeString(responseJSON, 'date');
    final password = _safeString(responseJSON, 'password');
    final providerId = _safeString(responseJSON, 'id_provider');
    final providerName = _safeString(responseJSON, 'provider');
    final amount = _safeString(responseJSON, 'amount_from');
    final receiveAmount = _safeString(responseJSON, 'amount_to');
    final addressProviderMemo = _safeString(responseJSON, 'address_provider_memo');

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
        'params': params,
        'url': uri.toString(),
      },
      responseData: {
        'id': id,
        'inputAddress': inputAddress,
        'refundAddress': refundAddress,
        'status': status,
        'payoutAddress': payoutAddress,
        'date': date,
        'password': password,
        'providerId': providerId,
        'providerName': providerName,
        'amount': amount,
        'receiveAmount': receiveAmount,
        'addressProviderMemo': addressProviderMemo,
        'statusCode': response.statusCode,
        'responseJSON': responseJSON,
      },
    );

    final amountToTrade = amount.isEmpty ? request.fromAmount : amount;
    final receiveAmountToTrade = receiveAmount.isEmpty ? request.toAmount : receiveAmount;

    return Trade(
      id: id,
      from: request.fromCurrency,
      to: request.toCurrency,
      provider: description,
      inputAddress: inputAddress,
      refundAddress: refundAddress,
      state: TradeState.deserialize(raw: status),
      password: password,
      providerId: providerId,
      providerName: providerName,
      createdAt: DateTime.tryParse(date)?.toLocal(),
      amount: amountToTrade,
      receiveAmount: receiveAmountToTrade,
      payoutAddress: payoutAddress,
      isSendAll: isSendAll,
      extraId: addressProviderMemo,
      toAddressExtraId: request.toAddressExtraId,
    );
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final uri = await _getUri(tradePath, {'id': id});
    return ProxyWrapper()
        .get(clearnetUri: uri, headers: {'API-Key': apiKey}).then((response) async {
      if (response.statusCode != 200)
        throw Exception('Unexpected http status: ${response.statusCode}');

      final responseListJson = json.decode(response.body) as List;
      final responseJSON = responseListJson.first as Map<String, dynamic>;
      final id = _safeString(responseJSON, 'trade_id');
      final payoutAddress = _safeString(responseJSON, 'address_user');
      final refundAddress = _safeString(responseJSON, 'refund_address');
      final inputAddress = _safeString(responseJSON, 'address_provider');
      final fromAmount = responseJSON['amount_from']?.toString() ?? '0';
      final password = _safeString(responseJSON, 'password');
      final providerId = _safeString(responseJSON, 'id_provider');
      final providerName = _safeString(responseJSON, 'provider');
      final memoVal = _safeString(responseJSON, 'address_provider_memo');
      final addressProviderMemo = memoVal.isEmpty ? null : memoVal;

      final fromCurrency = _safeString(responseJSON, 'ticker_from');
      final fromNetworkVal = _safeString(responseJSON, 'network_from');
      final fromNetwork = fromNetworkVal.isEmpty ? null : fromNetworkVal;
      final _normalizedFromNetwork = _normalizeNetworkType(fromNetwork ?? '');
      final fromTag = _normalizedFromNetwork.isEmpty ||
              _normalizedFromNetwork == fromCurrency.toUpperCase() ||
              _normalizedFromNetwork == 'Mainnet'
          ? null
          : _normalizedFromNetwork;

      final from = CryptoCurrency.safeParseCurrencyFromString(fromCurrency, tag: fromTag);

      final toCurrency = _safeString(responseJSON, 'ticker_to');
      final networkToVal = _safeString(responseJSON, 'network_to');
      final networkTo = networkToVal.isEmpty ? null : networkToVal;
      final _normalizedToNetwork = _normalizeNetworkType(networkTo ?? '');
      final toTag = _normalizedToNetwork.isEmpty ||
              _normalizedToNetwork == toCurrency.toUpperCase() ||
              _normalizedFromNetwork == 'Mainnet'
          ? null
          : _normalizedToNetwork;
      final to = CryptoCurrency.safeParseCurrencyFromString(toCurrency, tag: toTag);

      return Trade(
        id: id,
        from: from,
        to: to,
        provider: description,
        inputAddress: inputAddress,
        refundAddress: refundAddress,
        createdAt: DateTime.tryParse(_safeString(responseJSON, 'date')),
        amount: fromAmount,
        state: TradeState.deserialize(raw: _safeString(responseJSON, 'status')),
        payoutAddress: payoutAddress,
        password: password,
        providerId: providerId,
        providerName: providerName,
        extraId: addressProviderMemo,
      );
    });
  }

  Future<List<TrocadorPartners>> fetchProviders() async {
    final uri = await _getUri(providersListPath, {'api_key': apiKey});
    final response = await ProxyWrapper().get(clearnetUri: uri);

    if (response.statusCode != 200)
      throw Exception('Unexpected http status: ${response.statusCode}');

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    final providersJsonList = responseJSON['list'] as List<dynamic>;
    final filteredProvidersList = providersJsonList
        .map((providerJson) => TrocadorPartners.fromJson(providerJson as Map<String, dynamic>))
        .where((provider) => provider.rating != 'D')
        .toList();
    filteredProvidersList.sort((a, b) => a.rating.compareTo(b.rating));
    return filteredProvidersList;
  }

  String _networkFor(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.eth:
        return 'ERC20';
      case CryptoCurrency.maticpoly:
        return 'Mainnet';
      case CryptoCurrency.usdcpoly:
      case CryptoCurrency.usdtPoly:
      case CryptoCurrency.usdcEPoly:
        return 'MATIC';
      case CryptoCurrency.zec:
        return 'Mainnet';
      case CryptoCurrency.arb:
        return 'Mainnet';
      default:
        return currency.tag != null ? _normalizeTag(currency.tag!) : 'Mainnet';
    }
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.zec:
        return 'zec';
      case CryptoCurrency.usdcEPoly:
        return 'usdce';
      default:
        return currency.title.toLowerCase();
    }
  }

  String _normalizeTag(String tag) {
    if (tag.contains('ARB')) {
      return 'Arbitrum';
    }

    switch (tag) {
      case 'ETH':
        return 'ERC20';
      case 'TRX':
        return 'TRC20';
      case 'LN':
        return 'Lightning';
      case 'BSC':
        return 'BEP20';
      default:
        return tag.toLowerCase();
    }
  }

  String _normalizeNetworkType(String network) {
    return switch (network.toUpperCase()) {
      'ERC20' => 'ETH',
      'TRC20' => 'TRX',
      'BEP20' => 'BSC',
      'LIGHTNING' => 'LN',
      'MATIC' => 'POL',
      _ => network,
    };
  }

  Future<Uri> _getUri(String path, Map<String, String> queryParams) async {
    final uri = Uri.https(onionApiAuthority, path, queryParams);

    if (useTorOnly) return uri;

    try {
      await ProxyWrapper().get(clearnetUri: uri);

      return uri;
    } catch (e) {
      return Uri.https(clearNetAuthority, path, queryParams);
    }
  }

  /// Safe string extraction from API response. Handles different data types.
  static String _safeString(Map<String, dynamic> m, String key, [String nullError = '']) {
    final v = m[key];
    if (v == null) return nullError;
    if (v is String) return v;
    return v.toString();
  }
}

class TrocadorPartners {
  final String name;
  final String rating;
  final double? insurance;
  final bool? enabledMarkup;
  final double? eta;

  TrocadorPartners({
    required this.name,
    required this.rating,
    required this.insurance,
    required this.enabledMarkup,
    required this.eta,
  });

  factory TrocadorPartners.fromJson(Map<String, dynamic> json) {
    return TrocadorPartners(
      name: json['name'] as String? ?? '',
      rating: json['rating'] as String? ?? 'N/A',
      insurance: json['insurance'] as double?,
      enabledMarkup: json['enabledmarkup'] as bool?,
      eta: json['eta'] as double?,
    );
  }
}
