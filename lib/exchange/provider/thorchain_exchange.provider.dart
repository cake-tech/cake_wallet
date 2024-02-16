import 'dart:convert';

import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/utils/currency_pairs_utils.dart';
import 'package:collection/collection.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ThorChainExchangeProvider extends ExchangeProvider {
  ThorChainExchangeProvider({required this.tradesStore})
      : super(pairList: supportedPairs(_notSupported));

  static final List<CryptoCurrency> _notSupported = [
    ...(CryptoCurrency.all
        .where((element) => ![
              CryptoCurrency.btc,
              CryptoCurrency.eth,
              CryptoCurrency.ltc,
              CryptoCurrency.bch
            ].contains(element))
        .toList())
  ];

  static const _baseURL = 'https://thornode.ninerealms.com';
  static const _quotePath = '/thorchain/quote/swap';
  static const _txInfoPath = '/thorchain/tx/';
  static const _affiliateName = 'cakewallet';
  static const _affiliateBps = '0';

  final Box<Trade> tradesStore;

  @override
  String get title => 'ThorChain';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.thorChain;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<double> fetchRate(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required double amount,
      required bool isFixedRateMode,
      required bool isReceiveAmount}) async {
    try {
      if (amount == 0) return 0.0;

      final params = {
        'from_asset': _normalizeCurrency(from),
        'to_asset': _normalizeCurrency(to),
        'amount': _doubleToThorChainString(amount),
        'affiliate': _affiliateName,
        'affiliate_bps': _affiliateBps
      };

      final responseJSON = await _getSwapQuote(params);

      final expectedAmountOut = responseJSON['expected_amount_out'] as String? ?? '0.0';

      return _thorChainAmountToDouble(expectedAmountOut);
    } catch (e) {
      print(e.toString());
      return 0.0;
    }
  }

  @override
  Future<Limits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode}) async {
    final params = {
      'from_asset': _normalizeCurrency(from),
      'to_asset': _normalizeCurrency(to),
      'amount': _doubleToThorChainString(1),
      'affiliate': _affiliateName,
      'affiliate_bps': _affiliateBps
    };

    final responseJSON = await _getSwapQuote(params);
    final minAmountIn = responseJSON['recommended_min_amount_in'] as String? ?? '0.0';

    return Limits(min: _thorChainAmountToDouble(minAmountIn));
  }

  @override
  Future<Trade> createTrade({required TradeRequest request, required bool isFixedRateMode}) async {
    String formattedToAddress = request.toAddress.startsWith('bitcoincash:')
        ? request.toAddress.replaceFirst('bitcoincash:', '')
        : request.toAddress;

    final formattedFromAmount = double.parse(request.fromAmount);

    final params = {
      'from_asset': _normalizeCurrency(request.fromCurrency),
      'to_asset': _normalizeCurrency(request.toCurrency),
      'amount': _doubleToThorChainString(formattedFromAmount),
      'destination': formattedToAddress,
      'affiliate': _affiliateName,
      'affiliate_bps': _affiliateBps
    };

    final responseJSON = await _getSwapQuote(params);

    final inputAddress = responseJSON['inbound_address'] as String?;
    final memo = responseJSON['memo'] as String?;

    return Trade(
        id: '',
        from: request.fromCurrency,
        to: request.toCurrency,
        provider: description,
        inputAddress: inputAddress,
        createdAt: DateTime.now(),
        amount: request.fromAmount,
        state: TradeState.pending,
        payoutAddress: request.toAddress,
        memo: memo);
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    if (id.isEmpty) throw Exception('Trade id is empty');
    final formattedId = id.startsWith('0x') ? id.substring(2) : id;
    final uri = Uri.parse('$_baseURL$_txInfoPath$formattedId');
    final response = await http.get(uri);

    if (response.statusCode == 404) {
      throw Exception('Trade not found for id: $id');
    } else if (response.statusCode != 200) {
      throw Exception('Unexpected HTTP status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body);
    final observedTx = responseJSON['observed_tx'];
    if (observedTx == null) {
      throw Exception('No observed transaction found for id: $id');
    }

    final tx = observedTx['tx'];
    final String fromAddress = tx['from_address'] as String? ?? '';
    final String toAddress = tx['to_address'] as String? ?? '';
    final List<dynamic> coins = tx['coins'] as List<dynamic>;
    final String? memo = tx['memo'] as String?;
    final String toAsset = memo != null ? (memo.split(':')[1]).split('.')[0] : '';
    final status = observedTx['status'] as String?;
    final formattedStatus = status ?? 'pending';

    return Trade(
      id: id,
      from: CryptoCurrency.fromString(tx['chain'] as String? ?? ''),
      to: CryptoCurrency.fromString(toAsset),
      provider: description,
      inputAddress: fromAddress,
      payoutAddress: toAddress,
      amount: coins.first['amount'] as String? ?? '0.0',
      state: TradeState.deserialize(raw: formattedStatus),
      memo: memo,
    );
  }

  Future<Map<String, dynamic>> _getSwapQuote(Map<String, String> params) async {
    final uri = Uri.parse('$_baseURL$_quotePath${Uri(queryParameters: params)}');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Unexpected HTTP status: ${response.statusCode}');
    }

    if (response.body.contains('error')) {
      throw Exception('Unexpected response: ${response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  String _normalizeCurrency(CryptoCurrency currency) => '${currency.title}.${currency.title}';

  String _doubleToThorChainString(double amount) => (amount * 1e8).toInt().toString();

  double _thorChainAmountToDouble(String amount) => double.parse(amount) / 1e8;
}
