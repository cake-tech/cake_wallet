import 'dart:convert';

import 'package:cake_wallet/exchange/exchange_pair.dart';
import 'package:cake_wallet/exchange/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/trocador/trocador_request.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:http/http.dart';

class TrocadorExchangeProvider extends ExchangeProvider {
  TrocadorExchangeProvider()
      : _lastUsedRateId = '',
        super(pairList: _supportedPairs());

  static const List<CryptoCurrency> _notSupported = [
    CryptoCurrency.scrt,
    CryptoCurrency.stx,
    CryptoCurrency.zaddr,
  ];

  static List<ExchangePair> _supportedPairs() {
    final supportedCurrencies =
        CryptoCurrency.all.where((element) => !_notSupported.contains(element)).toList();

    return supportedCurrencies
        .map((i) => supportedCurrencies.map((k) => ExchangePair(from: i, to: k, reverse: true)))
        .expand((i) => i)
        .toList();
  }

  static const onionApiAuthority = 'trocadorfyhlu27aefre5u7zri66gudtzdyelymftvr4yjwcxhfaqsid.onion';
  static const clearNetAuthority = 'trocador.app';
  static const apiKey = secrets.trocadorApiKey;
  static const markup = secrets.trocadorExchangeMarkup;
  static const newRatePath = '/api/new_rate';
  static const createTradePath = 'api/new_trade';
  static const tradePath = 'api/trade';
  static const coinPath = 'api/coin';
  String _lastUsedRateId;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Trade> createTrade({required TradeRequest request, required bool isFixedRateMode}) {
    final _request = request as TrocadorRequest;
    return _createTrade(request: _request, isFixedRateMode: isFixedRateMode);
  }

  Future<Trade> _createTrade({
    required TrocadorRequest request,
    required bool isFixedRateMode,
  }) async {
    final params = <String, String>{
      'api_key': apiKey,
      'ticker_from': request.from.title.toLowerCase(),
      'ticker_to': request.to.title.toLowerCase(),
      'network_from': _networkFor(request.from),
      'network_to': _networkFor(request.to),
      'payment': isFixedRateMode ? 'True' : 'False',
      'min_kycrating': 'C',
      'markup': markup,
      'best_only': 'True',
      if (!isFixedRateMode) 'amount_from': request.fromAmount,
      if (isFixedRateMode) 'amount_to': request.toAmount,
      'address': request.address,
      'refund': request.refundAddress
    };

    if (isFixedRateMode) {
      await fetchRate(
        from: request.from,
        to: request.to,
        amount: double.tryParse(request.toAmount) ?? 0,
        isFixedRateMode: true,
        isReceiveAmount: true,
      );
      params['id'] = _lastUsedRateId;
    }

    final String apiAuthority = shouldUseOnionAddress ? await _getAuthority() : clearNetAuthority;

    final uri = Uri.https(apiAuthority, createTradePath, params);
    final response = await get(uri);

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
    final id = responseJSON['trade_id'] as String;
    final inputAddress = responseJSON['address_provider'] as String;
    final refundAddress = responseJSON['refund_address'] as String;
    final status = responseJSON['status'] as String;
    final state = TradeState.deserialize(raw: status);
    final payoutAddress = responseJSON['address_user'] as String;
    final date = responseJSON['date'] as String;
    final password = responseJSON['password'] as String;
    final providerId = responseJSON['id_provider'] as String;
    final providerName = responseJSON['provider'] as String;

    return Trade(
        id: id,
        from: request.from,
        to: request.to,
        provider: description,
        inputAddress: inputAddress,
        refundAddress: refundAddress,
        state: state,
        password: password,
        providerId: providerId,
        providerName: providerName,
        createdAt: DateTime.tryParse(date)?.toLocal(),
        amount: responseJSON['amount_from']?.toString() ?? request.fromAmount,
        payoutAddress: payoutAddress);
  }

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.trocador;

  @override
  Future<Limits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode}) async {
      
      final params = <String, String> {
        'api_key': apiKey,
        'ticker': from.title.toLowerCase(),
        'name': from.name,
      };
      
      final String apiAuthority = shouldUseOnionAddress ? await _getAuthority() : clearNetAuthority;
            final uri = Uri.https(apiAuthority, coinPath, params);
      
      final response = await get(uri);

      if (response.statusCode != 200) {
        throw Exception('Unexpected http status: ${response.statusCode}');
      }

      final responseJSON = json.decode(response.body) as List<dynamic>;
      
      if (responseJSON.isEmpty) {
        throw Exception('No data');
      }
      
      final coinJson = responseJSON.first as Map<String, dynamic>;
     
      
    return Limits(
      min: coinJson['minimum'] as double,
      max: coinJson['maximum'] as double,
    );
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

      final String apiAuthority = shouldUseOnionAddress ? await _getAuthority() : clearNetAuthority;

      final params = <String, String>{
        'api_key': apiKey,
        'ticker_from': from.title.toLowerCase(),
        'ticker_to': to.title.toLowerCase(),
        'network_from': _networkFor(from),
        'network_to': _networkFor(to),
        if (!isFixedRateMode) 'amount_from': amount.toString(),
        if (isFixedRateMode) 'amount_to': amount.toString(),
        'payment': isFixedRateMode ? 'True' : 'False',
        'min_kycrating': 'C',
        'markup': markup,
        'best_only': 'True',
      };

      final uri = Uri.https(apiAuthority, newRatePath, params);
      final response = await get(uri);
      final responseJSON = json.decode(response.body) as Map<String, dynamic>;
      final fromAmount = double.parse(responseJSON['amount_from'].toString());
      final toAmount = double.parse(responseJSON['amount_to'].toString());
      final rateId = responseJSON['trade_id'] as String? ?? '';

      if (rateId.isNotEmpty) {
        _lastUsedRateId = rateId;
      }

      return isReceiveAmount ? (amount / fromAmount) : (toAmount / amount);
    } catch (e) {
      print(e.toString());
      return 0.0;
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final String apiAuthority = shouldUseOnionAddress ? await _getAuthority() : clearNetAuthority;
    final uri = Uri.https(apiAuthority, tradePath, {'api_key': apiKey, 'id': id});
    return get(uri).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Unexpected http status: ${response.statusCode}');
      }

      final responseListJson = json.decode(response.body) as List;

      final responseJSON = responseListJson.first;
      final id = responseJSON['trade_id'] as String;
      final inputAddress = responseJSON['address_user'] as String;
      final refundAddress = responseJSON['refund_address'] as String;
      final payoutAddress = responseJSON['address_provider'] as String;
      final fromAmount = responseJSON['amount_from']?.toString() ?? '0';
      final from = CryptoCurrency.fromString(responseJSON['ticker_from'] as String);
      final to = CryptoCurrency.fromString(responseJSON['ticker_to'] as String);
      final state = TradeState.deserialize(raw: responseJSON['status'] as String);
      final date = DateTime.parse(responseJSON['date'] as String);
      final password = responseJSON['password'] as String;
      final providerId = responseJSON['id_provider'] as String;
      final providerName = responseJSON['provider'] as String;

      return Trade(
        id: id,
        from: from,
        to: to,
        provider: description,
        inputAddress: inputAddress,
        refundAddress: refundAddress,
        createdAt: date,
        amount: fromAmount,
        state: state,
        payoutAddress: payoutAddress,
        password: password,
        providerId: providerId,
        providerName: providerName,
      );
    });
  }

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  bool get shouldUseOnionAddress => true;

  @override
  String get title => 'Trocador';

  String _networkFor(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.eth:
        return 'ERC20';
      case CryptoCurrency.maticpoly:
        return 'Mainnet';
      case CryptoCurrency.usdcpoly:
        return 'MATIC';
      case CryptoCurrency.zec:
        return 'Mainnet';
      default:
        return currency.tag != null ? _normalizeTag(currency.tag!) : 'Mainnet';
    }
  }

  String _normalizeTag(String tag) {
    switch (tag) {
      case 'ETH':
        return 'ERC20';
      case 'TRX':
        return 'TRC20';
      default:
        return tag.toLowerCase();
    }
  }

  Future<String> _getAuthority() async {
    try {
      final uri = Uri.https(onionApiAuthority, '/api/trade');
      await get(uri);
      return onionApiAuthority;
    } catch (e) {
      return clearNetAuthority;
    }
  }
}
