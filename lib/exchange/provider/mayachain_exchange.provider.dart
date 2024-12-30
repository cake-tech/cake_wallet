import 'dart:convert';

import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/utils/currency_pairs_utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class MayaChainExchangeProvider extends ExchangeProvider {
  MayaChainExchangeProvider({required this.tradesStore})
      : super(pairList: supportedPairs(_notSupported));

  static final List<CryptoCurrency> _notSupported = [
    ...(CryptoCurrency.all
        .where((element) => ![
              CryptoCurrency.btc,
              CryptoCurrency.dash,
              CryptoCurrency.eth,
              CryptoCurrency.pepe,
              CryptoCurrency.usdc,
              CryptoCurrency.usdterc20,
            ].contains(element))
        .toList())
  ];

  static final isRefundAddressSupported = [CryptoCurrency.eth];

  static const _baseNodeURL = 'https://mayanode.mayachain.info';
  static const _baseURL = 'https://midgard.mayachain.info';
  static const _quotePath = '/mayachain/quote/swap';
  static const _txInfoPath = '/mayachain/tx/status/';
  static const _affiliateName = 'cakewallet'; // register a shorter one
  static const _affiliateBps = '175';
  static const _nameLookUpPath = 'v2/mayaname/lookup/';
  static const _affiliateBps = '175';
  static const _toleranceBps = '100';
  static const _streamingInterval = '3';

  final Box<Trade> tradesStore;

  @override
  String get title => 'MAYAChain';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.mayaChain;

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
        'amount': _doubleToMayaChainString(amount),
        'streaming_interval': _streamingInterval,
        'tolerance_bps': _toleranceBps,
        'affiliate': _affiliateName,
        'affiliate_bps': _affiliateBps
      };

      final responseJSON = await _getSwapQuote(params);

      final expectedAmountOut = responseJSON['expected_amount_out'] as String? ?? '0.0';

      return _mayaChainAmountToDouble(expectedAmountOut) / amount;
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
      'amount': _doubleToMayaChainString(1),
      'streaming_interval': _streamingInterval,
      'tolerance_bps': _toleranceBps,
      'affiliate': _affiliateName,
      'affiliate_bps': _affiliateBps
    };

    final responseJSON = await _getSwapQuote(params);
    final minAmountIn = responseJSON['recommended_min_amount_in'] as String? ?? '0.0';

    return Limits(min: _mayaChainAmountToDouble(minAmountIn));
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
    required bool isFixedRateMode,
    required bool isSendAll,
  }) async {
    String formattedToAddress = request.toAddress;
    
    final formattedFromAmount = double.parse(request.fromAmount);

    final params = {
      'from_asset': _normalizeCurrency(request.fromCurrency),
      'to_asset': _normalizeCurrency(request.toCurrency),
      'amount': _doubleToMayaChainString(formattedFromAmount),
      'destination': formattedToAddress,
      'streaming_interval': _streamingInterval,
      'tolerance_bps': _toleranceBps,
      'affiliate': _affiliateName,
      'affiliate_bps': _affiliateBps,
      'refund_address':
          isRefundAddressSupported.contains(request.fromCurrency) ? request.refundAddress : '',
    };

    final responseJSON = await _getSwapQuote(params);

    final inputAddress = responseJSON['inbound_address'] as String?;
    final memo = responseJSON['memo'] as String?;
    final directAmountOutResponse = responseJSON['expected_amount_out'] as String?;

    String? receiveAmount;
    if (directAmountOutResponse != null) {
      receiveAmount = _mayaChainAmountToDouble(directAmountOutResponse).toString();
    }

    return Trade(
      id: '',
      from: request.fromCurrency,
      to: request.toCurrency,
      provider: description,
      inputAddress: inputAddress,
      createdAt: DateTime.now(),
      amount: request.fromAmount,
      receiveAmount: receiveAmount ?? request.toAmount,
      state: TradeState.notFound,
      payoutAddress: request.toAddress,
      memo: memo,
      isSendAll: isSendAll,
    );
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    if (id.isEmpty) throw Exception('Trade id is empty');
    final formattedId = id.startsWith('0x') ? id.substring(2) : id;
    final uri = Uri.https(_baseNodeURL, '$_txInfoPath$formattedId');
    final response = await http.get(uri);

    if (response.statusCode == 404) {
      throw Exception('Trade not found for id: $formattedId');
    } else if (response.statusCode != 200) {
      throw Exception('Unexpected HTTP status: ${response.statusCode}');
    }

    final responseJSON = json.decode(response.body);
    final Map<String, dynamic> stagesJson = responseJSON['stages'] as Map<String, dynamic>;

    final inboundObservedStarted = stagesJson['inbound_observed']?['started'] as bool? ?? true;
    if (!inboundObservedStarted) {
      throw Exception('Trade has not started for id: $formattedId');
    }

    final currentState = _updateStateBasedOnStages(stagesJson) ?? TradeState.notFound;

    final tx = responseJSON['tx'];
    final String fromAddress = tx['from_address'] as String? ?? '';
    final String toAddress = tx['to_address'] as String? ?? '';
    final List<dynamic> coins = tx['coins'] as List<dynamic>;
    final String? memo = tx['memo'] as String?;

    final parts = memo?.split(':') ?? [];

    final String toChain = parts.length > 1 ? parts[1].split('.')[0] : '';
    final String toAsset = parts.length > 1 && parts[1].split('.').length > 1
        ? parts[1].split('.')[1].split('-')[0]
        : '';

    final formattedToChain = CryptoCurrency.fromString(toChain);
    final toAssetWithChain = CryptoCurrency.fromString(toAsset, walletCurrency: formattedToChain);

    final plannedOutTxs = responseJSON['planned_out_txs'] as List<dynamic>?;
    final isRefund = plannedOutTxs?.any((tx) => tx['refund'] == true) ?? false;

    return Trade(
      id: id,
      from: CryptoCurrency.fromString(tx['chain'] as String? ?? ''),
      to: toAssetWithChain,
      provider: description,
      inputAddress: fromAddress,
      payoutAddress: toAddress,
      amount: coins.first['amount'] as String? ?? '0.0',
      state: currentState,
      memo: memo,
      isRefund: isRefund,
    );
  }

  static Future<Map<String, String>?>? lookupAddressByName(String name) async {
    final uri = Uri.https(_baseURL, '$_nameLookUpPath$name');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return null;
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final entries = body['entries'] as List<dynamic>?;

    if (entries == null || entries.isEmpty) {
      return null;
    }

    Map<String, String> chainToAddressMap = {};

    for (final entry in entries) {
      final chain = entry['chain'] as String;
      final address = entry['address'] as String;
      chainToAddressMap[chain] = address;
    }

    return chainToAddressMap;
  }

  Future<Map<String, dynamic>> _getSwapQuote(Map<String, String> params) async {
    Uri uri = Uri.https(_baseNodeURL, _quotePath, params);

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Unexpected HTTP status: ${response.statusCode}');
    }

    if (response.body.contains('error')) {
      throw Exception('Unexpected response: ${response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  String _normalizeCurrency(CryptoCurrency currency) {
    final networkTitle = currency.tag == 'ETH' ? 'ETH' : currency.title;
    return '$networkTitle.${currency.title}';
  }

  String _doubleTomayaChainString(double amount) => (amount * 1e8).toInt().toString();

  double _mayaChainAmountToDouble(String amount) => double.parse(amount) / 1e8;

  TradeState? _updateStateBasedOnStages(Map<String, dynamic> stages) {
    TradeState? currentState;

    if (stages['inbound_observed']['completed'] as bool? ?? false) {
      currentState = TradeState.confirmation;
    }
    if (stages['inbound_confirmation_counted']['completed'] as bool? ?? false) {
      currentState = TradeState.confirmed;
    }
    if (stages['inbound_finalised']['completed'] as bool? ?? false) {
      currentState = TradeState.processing;
    }
    if (stages['swap_finalised']['completed'] as bool? ?? false) {
      currentState = TradeState.traded;
    }
    if (stages['outbound_signed']['completed'] as bool? ?? false) {
      currentState = TradeState.success;
    }

    return currentState;
  }
}
