import "dart:convert";
import 'package:decimal/decimal.dart';

import "package:collection/collection.dart";
import "package:http/http.dart" as very_insecure_http_do_not_use;
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/limits.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/wallet_base.dart";
import "pegaroute/pegaroute_api.dart";
import "pegaroute/pegaroute_amount.dart";
import "pegaroute/pegaroute_asset_identity.dart";
import "pegaroute/pegaroute_capability_gate.dart";
import "pegaroute/pegaroute_configuration.dart";
import "pegaroute/pegaroute_currency_mapper.dart";
import "pegaroute/pegaroute_execution_terms.dart";
import "pegaroute/pegaroute_provider_preferences.dart";
import "pegaroute/pegaroute_trade_record.dart";
import "pegaroute/pegaroute_trade_store.dart";

export "pegaroute/pegaroute_api.dart" show PegarouteApiError, PegarouteSwapAttemptException;

typedef PegarouteRequest = Future<Map<String, dynamic>> Function(
    String method, Uri uri, Map<String, String> headers, String? body);

class PegaRouteExchangeProvider extends ExchangeProvider {
  PegaRouteExchangeProvider({PegarouteRequest? request, PegarouteApiClient? apiClient,
      PegarouteConfiguration? configuration, PegarouteTradeStore? store,
      this.providerPreferences, DateTime Function()? quoteClock})
      : _quoteClock = quoteClock ?? DateTime.now,
        apiClient = apiClient ?? PegarouteApiClient(configuration: configuration, clock: quoteClock,
          get: request == null ? null : (uri, headers) async =>
              very_insecure_http_do_not_use.Response(jsonEncode(await request('GET', uri, headers, null)), 200),
          post: request == null ? null : (uri, headers, body) async =>
              very_insecure_http_do_not_use.Response(jsonEncode(await request('POST', uri, headers, body)),
                  uri.path == '/swap' ? 202 : 200)),
        store = store ?? PegarouteTradeStore();

  final PegarouteApiClient apiClient;
  final PegarouteTradeStore store;
  final PegarouteProviderPreferences? providerPreferences;
  final DateTime Function() _quoteClock;
  final Map<String, String> _selectedRoutes = {};
  final Map<String, Set<String>> _tokens = {};
  Set<String>? _chains;
  bool _creating = false;
  static const _mapper = PegarouteCurrencyMapper();

  @override
  String get title => "Pegaroute";

  @override
  bool get isAvailable => apiClient.configuration.isValid;

  @override
  bool get isEnabled => isAvailable;

  @override
  bool get supportsFixedRate => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.pegaRoute;

  @override
  Future<bool> checkIsAvailable() async => isAvailable;

  static bool allowsExternal(ExchangeProviderDescription provider) =>
      provider != ExchangeProviderDescription.pegaRoute;

  static bool supportsPair(CryptoCurrency from, CryptoCurrency to) {
    try {
      final source = _mapper.map(from);
      final destination = _mapper.map(to);
      return PegarouteCurrencyMapper.quoteSourceChains.contains(source.chain) &&
          (source.chain != destination.chain || source.token != destination.token);
    } catch (_) { return false; }
  }

  static bool supportsWallet(WalletBase wallet, CryptoCurrency currency) {
    try { return PegarouteCapabilityGate.source(wallet, _mapper.map(currency)) &&
        sourceBalance(wallet, currency) != null; }
    catch (_) { return false; }
  }

  // Max selects an exact amount before quoting. Native assets need a fee estimate.
  static bool supportsMax(WalletBase wallet, CryptoCurrency currency) {
    try {
      PegarouteAssetIdentity.validateMetadata(currency);
      final asset = _mapper.map(currency);
      return (asset.token != asset.nativeToken ||
          PegarouteCapabilityGate.evmChains.containsKey(asset.chain) ||
          PegarouteCapabilityGate.utxo.contains(asset.chain)) && supportsWallet(wallet, currency);
    } catch (_) { return false; }
  }

  static bool sameAsset(CryptoCurrency a, CryptoCurrency b) {
    try { return a.decimals == b.decimals && _mapper.matchesCanonicalTuple(a, _mapper.map(b)); }
    catch (_) { return false; }
  }

  static Money? sourceBalance(WalletBase wallet, CryptoCurrency currency) {
    final asset = _mapper.map(currency);
    Money? result;
    for (final entry in wallet.balance.entries) {
      if (!_mapper.matchesCanonicalTuple(entry.key, asset)) continue;
      final available = entry.value.available;
      if (result != null || entry.key.decimals != currency.decimals ||
          available.currency is! CryptoCurrency ||
          (available.currency as CryptoCurrency).decimals != currency.decimals ||
          !_mapper.matchesCanonicalTuple(available.currency as CryptoCurrency, asset)) return null;
      result = available;
    }
    return result;
  }

  // All four supported providers, including Instaswap, are decentralized.
  // Explicit preferences still apply, including after asynchronous quote work.
  bool _enabled(String provider) =>
      PegarouteCapabilityGate.providers.contains(provider) &&
      (providerPreferences?.isEnabled(provider) ?? true);

  String _key(CryptoCurrency from, CryptoCurrency to, String amount) {
    final source = _mapper.map(from);
    final destination = _mapper.map(to);
    return '${source.chain}/${source.token}/${from.decimals}/${destination.chain}/${destination.token}/${to.decimals}/$amount';
  }

  Future<void> _catalog(PegarouteAssetId source, PegarouteAssetId destination) async {
    _chains ??= await apiClient.chains();
    for (final asset in [source, destination]) {
      if (!_chains!.contains(asset.chain)) throw StateError('Pegaroute chain unavailable');
      _tokens[asset.chain] ??= await apiClient.tokens(asset.chain);
      if (!_tokens[asset.chain]!.contains(asset.token)) throw StateError('Pegaroute asset unavailable');
    }
  }

  Future<PegarouteValidatedQuote> _quote(CryptoCurrency from, CryptoCurrency to, String amount,
      {TradeRequest? request, String? sender}) async {
    PegarouteAssetIdentity.validateMetadata(from);
    PegarouteAssetIdentity.validateMetadata(to);
    final source = _mapper.map(from);
    final destination = _mapper.map(to);
    await _catalog(source, destination);
    return apiClient.quote(PegarouteQuoteRequest(fromChain: source.chain, fromToken: source.token,
        toChain: destination.chain, toToken: destination.token, amount: amount,
        senderAddress: sender, destinationAddress: request?.toAddress,
        refundAddress: request?.refundAddress));
  }

  PegarouteRoute _route(PegarouteValidatedQuote quote, PegarouteAssetId source,
      {String? selected, void Function(Limits)? onLimits}) {
    if (!_quoteClock().isBefore(DateTime.parse(quote.response.expiresAt))) throw StateError('Quote expired');
    final supported = quote.response.routes.where((route) =>
        (selected == null || route.provider == selected) && _enabled(route.provider) &&
        PegarouteCapabilityGate.quote(source, route)).toList();
    final routes = supported.where((route) {
          final minimum = route.minAmount;
          if (minimum == null) return true;
          observationAmount(minimum);
          return _compareOutput((jsonDecode(quote.requestJson) as Map)['amount'] as String, minimum) >= 0;
        }).toList();
    for (final route in routes) { observationAmount(route.expectedOutput, positive: true); }
    routes.sort((a, b) => _compareOutput(b.expectedOutput, a.expectedOutput));
    if (routes.isEmpty) {
      double? minimum;
      for (final value in [
        ...supported.map((route) => PegarouteApiError.limit(route.minAmount)),
        ...quote.response.warnings
            .where((warning) => warning.code == 'AMOUNT_TOO_LOW' && _enabled(warning.provider))
            .map((warning) => PegarouteApiError.minimum(
                {'message': warning.message, 'userMessage': warning.userMessage})),
      ].whereType<double>()) {
        if (minimum == null || value < minimum) minimum = value;
      }
      if (minimum != null) onLimits?.call(Limits(min: minimum, max: null));
      throw StateError('No supported Pegaroute route');
    }
    if (routes.where((route) => route.provider == routes.first.provider).length != 1) {
      throw StateError('Ambiguous Pegaroute route');
    }
    return routes.first;
  }

  @override
  Future<Limits?> fetchLimits({required CryptoCurrency from, required CryptoCurrency to,
      required bool isFixedRateMode}) async {
    if (isFixedRateMode || !supportsPair(from, to) || !isAvailable ||
        !PegarouteCapabilityGate.providers.any(_enabled)) return null;
    // There is no pair-wide minimum. The current amount's quote supplies limits.
    return Limits(min: 0, max: null);
  }

  @override
  Future<double> fetchRate({required CryptoCurrency from, required CryptoCurrency to,
      required double amount, required bool isFixedRateMode, required bool isReceiveAmount}) async {
    if (!amount.isFinite || amount <= 0 || isFixedRateMode || isReceiveAmount) return 0;
    try {
      final decimal = Decimal.parse(amount.toString()).toString();
      return fetchRateExact(from: from, to: to, amount: decimal);
    } catch (_) { return 0; }
  }

  Future<double> fetchRateExact({required CryptoCurrency from, required CryptoCurrency to,
      required String amount, void Function(Limits)? onLimits}) async {
    if (!supportsPair(from, to) || !isAvailable) return 0;
    _selectedRoutes.remove(_key(from, to, amount));
    if (!PegarouteCapabilityGate.providers.any(_enabled)) return 0;
    try {
      if (BigInt.parse(PegarouteExecutionTerms.toBaseUnits(amount, from.decimals)) <= BigInt.zero) return 0;
      final quote = await _quote(from, to, amount);
      final route = _route(quote, _mapper.map(from), onLimits: onLimits);
      final rate = double.parse(route.expectedOutput) / double.parse(amount);
      if (!rate.isFinite || rate <= 0) return 0;
      _selectedRoutes[_key(from, to, amount)] = route.provider;
      onLimits?.call(Limits(min: PegarouteApiError.limit(route.minAmount) ?? 0, max: null));
      return rate;
    } on PegarouteApiError catch (error) {
      if (error.code == 'AMOUNT_TOO_LOW' && error.minAmount != null &&
          error.provider != null && _enabled(error.provider!)) {
        onLimits?.call(Limits(min: error.minAmount, max: null));
      }
      return 0;
    } catch (_) { return 0; }
  }

  static int _compareOutput(String a, String b) {
    final first = a.split('.');
    final second = b.split('.');
    final aPlaces = first.length == 1 ? 0 : first.last.length;
    final bPlaces = second.length == 1 ? 0 : second.last.length;
    return (BigInt.parse(first.join()) * BigInt.from(10).pow(bPlaces))
        .compareTo(BigInt.parse(second.join()) * BigInt.from(10).pow(aPlaces));
  }

  @override
  Future<Trade> createTrade({required TradeRequest request, required bool isFixedRateMode,
      required bool isSendAll}) =>
      Future.error(StateError('Pegaroute creation requires a bound Cake wallet'));

  Future<Trade> createBoundTrade({required TradeRequest request, required String walletId,
      required String sender, required int? chainId, required bool isFixedRateMode,
      required bool isSendAll, required bool Function() isCurrent}) async {
    if (_creating) throw StateError('Pegaroute creation already in progress');
    _creating = true;
    try {
      if (!supportsPair(request.fromCurrency, request.toCurrency) || isFixedRateMode ||
          request.isFixedRate || isSendAll || request.toAddressExtraId.isNotEmpty) {
        throw StateError('Unsupported Pegaroute request');
      }
      final source = _mapper.map(request.fromCurrency);
      final destination = _mapper.map(request.toCurrency);
      if (PegarouteExecutionTerms.chainIdFor(source.chain) != chainId) throw StateError('Wrong source chain');
      for (final value in [walletId, sender, request.toAddress, request.refundAddress]) {
        if (value.isEmpty || value.trim() != value) throw StateError('Incomplete bound intent');
      }
      if (BigInt.parse(PegarouteExecutionTerms.toBaseUnits(request.fromAmount, request.fromCurrency.decimals)) <= BigInt.zero) {
        throw StateError('Source principal must be positive');
      }
      final key = _key(request.fromCurrency, request.toCurrency, request.fromAmount);
      final selected = _selectedRoutes[key];
      if (selected == null) throw StateError('Exact quote required before creation');
      if (!isCurrent()) throw StateError('Wallet or quote intent changed');
      final quote = await _quote(request.fromCurrency, request.toCurrency, request.fromAmount,
          request: request, sender: sender);
      final reviewed = _route(quote, source, selected: selected);
      final preflight = apiClient.preflight(quote: quote, route: reviewed,
          request: PegarouteSwapRequest(fromChain: source.chain, fromToken: source.token,
              toChain: destination.chain, toToken: destination.token, amount: request.fromAmount,
              senderAddress: sender, destinationAddress: request.toAddress,
              refundAddress: request.refundAddress, quoteId: quote.response.quoteId, routeProvider: selected));
      if (!isCurrent()) throw StateError('Wallet or quote intent changed');
      // Consume before POST; a transport, validation or persistence failure is not retry permission.
      _selectedRoutes.remove(key);
      final result = await apiClient.swap(preflight);
      try {
        final response = result.response;
        if (!result.isBoundTo(apiClient) || response.provider.name != selected ||
            response.providerType != reviewed.providerType ||
            !PegarouteExecutionTerms.sameRouteEcho(PegarouteExecutionTerms.routeSnapshot(reviewed),
                response.route, response.providerType, true) ||
            !PegarouteCapabilityGate.execution(source, response.execution, selected, chainId) ||
            !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(response.transactionId)) {
          throw StateError('Created route changed');
        }
        PegarouteExecutionTerms.validateProviderDetails(provider: response.provider,
            route: PegarouteExecutionTerms.routeSnapshot(reviewed), execution: response.execution,
            sourceChain: source.chain, sourceAmount: request.fromAmount);
        var expiry = pegarouteRouteDeadline(reviewed.expiry);
        final depositExpiry = response.provider.instaswapSwapLite?.expiresAt;
        if (depositExpiry != null) {
          final parsed = DateTime.parse(depositExpiry);
          if (expiry == null || parsed.isBefore(expiry)) expiry = parsed;
        }
        final trade = Trade(id: response.transactionId, provider: description, state: TradeState.created,
            from: request.fromCurrency, to: request.toCurrency, amount: request.fromAmount,
            receiveAmount: response.route.expectedOutput, inputAddress: response.execution.to,
            memo: response.execution.memo, payoutAddress: request.toAddress,
            refundAddress: request.refundAddress, walletId: walletId, fromWalletAddress: sender,
            chainId: chainId, providerName: selected, providerId: response.provider.referenceId,
            createdAt: DateTime.now(), expiredAt: expiry);
        observationAmount(trade.receiveAmount, positive: true);
        trade.routerData = PegarouteTradeRecord.create(trade, execution: response.execution, route: reviewed).encode();
        final saved = await store.create(trade);
        if (!isCurrent() || !_enabled(selected)) throw StateError('Order saved for previous intent; do not repay');
        return saved;
      } catch (error) {
        throw PegarouteSwapAttemptException(cause: error,
            providerTransactionId: result.response.transactionId,
            userMessage: 'Order creation may have completed. Automatic retry is disabled.');
      }
    } finally { _creating = false; }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final captured = await store.read(id);
    final record = PegarouteTradeRecord.read(captured);
    final response = await apiClient.status(id);
    final input = response.input;
    final output = response.output;
    if (response.transactionId != id ||
        !PegarouteExecutionTerms.sameRouteEcho(record.route, response.route, null) ||
        input.chain != record.source || input.token != record.sourceAsset.token ||
        output.chain != record.destination || output.token != record.destinationAsset.token ||
        input.address == null ||
        !PegarouteExecutionTerms.sameAddress(record.source, input.address!, captured.fromWalletAddress!) ||
        !_sameRefund(record.source, input.refundAddress, captured.refundAddress!, captured.fromWalletAddress!) ||
        (input.providerReferenceSupplied && input.providerReferenceId != captured.providerId) ||
        !PegarouteExecutionTerms.sameAddress(record.destination, output.address, captured.payoutAddress!) ||
        record.sourceUnits(input.amount) != record.sourceUnits(captured.amount)) {
      throw StateError('Provider status does not match bound order');
    }
    if (response.provider != null && (response.provider!.name != captured.providerName ||
        response.provider!.referenceId != captured.providerId)) throw StateError('Status provider changed');
    if (response.execution != null && !const DeepCollectionEquality().equals(
        response.execution!.toJson(), record.execution.toJson())) throw StateError('Status execution changed');
    for (final details in [input.instaswapSwapLite, response.provider?.instaswapSwapLite]) {
      if (details == null) continue;
      if (details.txid != captured.providerId || details.depositAddress != captured.inputAddress ||
          (details.depositAmountExact != null && !pegarouteSameAmount(details.depositAmountExact!, captured.amount))) {
        throw StateError('Status provider deposit identity changed');
      }
    }
    const states = {'pending': ('created', 'pending'), 'submitted': ('confirming', 'executing'),
      'executing': ('exchanging', 'executing'), 'confirming': ('sending', 'executing'),
      'completed': ('success', 'success'), 'failed': ('failed', 'fail'), 'refunded': ('refunded', 'fail')};
    final state = states[response.internalStatus];
    if (state == null || response.status != state.$2) throw StateError('Inconsistent provider status');
    if (output.amount != null) observationAmount(output.amount);
    if (input.txHash != null) validateHash(input.txHash!, record.source);
    if (output.txHash != null) validateHash(output.txHash!, record.destination);
    final refund = response.refund;
    Map<String, dynamic>? refundObservation;
    if (refund != null) {
      for (final value in [refund.amount, refund.originalAmount, refund.feeDeducted]) observationAmount(value);
      if (refund.chain != record.source || refund.refundAddress.trim().isEmpty ||
          refund.refundAddress.length > 512) throw StateError('Invalid refund observation');
      // The reported return destination is an observation, not a replacement for
      // the configured refund address in the immutable creation intent.
      if (refund.txHash != null) validateHash(refund.txHash!, record.source);
      refundObservation = {'status': refund.status, 'chain': refund.chain, 'amount': refund.amount,
        'originalAmount': refund.originalAmount, 'feeDeducted': refund.feeDeducted,
        'feeDescription': refund.feeDescription, 'refundAddress': refund.refundAddress,
        if (refund.txHash != null) 'txHash': refund.txHash,
        if (refund.completedAt != null) 'completedAt': refund.completedAt};
    }
    // Provider writes reload/merge claims and approvals atomically; callers must not generic-save this result.
    return store.observe(captured, state: state.$1, sourceHash: input.txHash,
        outputHash: output.txHash, receiveAmount: output.amount,
        refund: refund != null || state.$1 == 'refunded', refundObservation: refundObservation);
  }

  static bool _sameRefund(String chain, String? observed, String configured, String sender) =>
      observed == null
          ? PegarouteExecutionTerms.sameAddress(chain, configured, sender)
          : PegarouteExecutionTerms.sameAddress(chain, observed, configured);

  Future<void> notifySourceHash(Trade trade, String hash) async {
    final captured = await store.latest(trade);
    final record = PegarouteTradeRecord.read(captured);
    validateHash(hash, record.source);
    if (captured.txId != hash) throw StateError('Hash is not persisted funding evidence');
    await apiClient.notifySourceHash(captured.id, hash, chain: record.source);
  }

  static void observationAmount(Object? value, {bool positive = false}) {
    if (value is! String || value.length > 512 ||
        !RegExp(r'^(0|[1-9][0-9]*)(\.[0-9]+)?$').hasMatch(value) ||
        (positive && BigInt.parse(value.replaceAll('.', '')) == BigInt.zero)) {
      throw const FormatException('Invalid observed amount');
    }
  }

  static void validateHash(String hash, String chain) => PegarouteTradeRecord.validateHash(hash, chain);
}
