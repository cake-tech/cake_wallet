import 'dart:convert';
import 'dart:math';

import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_not_found_exception.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';

/// GhostSwap Partners API — a non-custodial swap provider (partners.ghostswap.io).
///
/// Server flow (https://partners.ghostswap.io/docs):
///   POST /v1/quotes        -> live quote (rate, min/max, amountUserReceives)
///   POST /v1/swaps         -> create swap (requires Idempotency-Key header)
///   GET  /v1/swaps/{id}     -> poll status
///
/// Non-negotiable rules honoured here (AGENTS.md):
///  - Display `amountUserReceives` (already net of network fee), not raw amountTo.
///  - Sender/refund address is always sent (AML requirement).
///  - One Idempotency-Key (UUID v4) per createTrade call.
///  - Never reveal AML/screening to the user: surface error.message verbatim,
///    map the `hold` status to a neutral "processing" state, never auto-retry.
class GhostSwapExchangeProvider extends ExchangeProvider {
  GhostSwapExchangeProvider();

  // Requests go through GhostWallet's server-side proxy (a Cloudflare Worker),
  // which injects the partner `Authorization: Bearer PUBLIC:SECRET` header so
  // the key never ships inside the APK. The proxy forwards /health and /v1/*
  // verbatim to partners-api.ghostswap.io.
  static const apiBaseUrl = 'app-api.ghostswap.io';
  static const quotesPath = '/v1/quotes';
  static const swapsPath = '/v1/swaps';
  static const currenciesPath = '/v1/currencies';
  static const healthPath = '/health';

  // No Authorization header here — the proxy injects "Bearer PUBLIC:SECRET"
  // server-side. The per-call Idempotency-Key is still set in createTrade.
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  @override
  String get title => 'GhostSwap';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  // Currencies that need a memo/destination-tag (XRP, XLM, EOS…) are filtered
  // out upstream, so never send an extraId on swap creation.
  @override
  bool get supportsMemoOrDestinationTag => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.ghostSwap;

  @override
  Future<bool> checkIsAvailable() async {
    try {
      final uri = Uri.https(apiBaseUrl, healthPath);
      final response = await ProxyWrapper().get(clearnetUri: uri);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Limits?> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    try {
      final quote = await _quote(
        from: from,
        to: to,
        amountFrom: '1',
        isFixedRateMode: isFixedRateMode,
      );
      if (quote == null) return null;
      return Limits(min: _toDouble(quote['min']), max: _toDouble(quote['max']));
    } catch (e) {
      printV('GhostSwap fetchLimits: $e');
      return null;
    }
  }

  @override
  Future<double> fetchRate({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required double amount,
    required bool isFixedRateMode,
    required bool isReceiveAmount,
  }) async {
    try {
      if (amount == 0) return 0.0;
      final quote = await _quote(
        from: from,
        to: to,
        amountFrom: amount.toString(),
        isFixedRateMode: isFixedRateMode,
      );
      if (quote == null) return 0.0;

      // Effective NET rate so the UI shows amountUserReceives (already net of fees).
      final amountFrom = _toDouble(quote['amountFrom']) ?? amount;
      final userReceives = _toDouble(quote['amountUserReceives']) ??
          _toDouble(quote['amountTo']) ??
          0.0;
      if (amountFrom <= 0) return 0.0;
      return userReceives / amountFrom;
    } catch (e) {
      printV('GhostSwap fetchRate: $e');
      return 0.0;
    }
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
    required bool isFixedRateMode,
    required bool isSendAll,
  }) async {
    // Fixed mode needs a fresh rateId from a quote taken at confirm time.
    String? rateId;
    if (isFixedRateMode) {
      final quote = await _quote(
        from: request.fromCurrency,
        to: request.toCurrency,
        amountFrom: request.fromAmount,
        isFixedRateMode: true,
      );
      rateId = quote?['rateId']?.toString();
    }

    final body = <String, dynamic>{
      'from': _ticker(request.fromCurrency),
      'to': _ticker(request.toCurrency),
      'amountFrom': request.fromAmount,
      'address': request.toAddress,
      // Sender/refund address is REQUIRED (AML). Always send it.
      'refundAddress': request.refundAddress,
      'partnerReferenceId': 'cakewallet_${DateTime.now().millisecondsSinceEpoch}',
      'mode': _mode(isFixedRateMode),
      if (rateId != null && rateId.isNotEmpty) 'rateId': rateId,
    };

    final headers = {..._headers, 'Idempotency-Key': _uuidV4()};
    final uri = Uri.https(apiBaseUrl, swapsPath);
    final response =
        await ProxyWrapper().post(clearnetUri: uri, headers: headers, body: json.encode(body));

    final decoded = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      // Neutral handling: surface the API's message verbatim, never reveal
      // AML/screening, never auto-retry (covers 422 exchange_not_processable).
      throw Exception(_errorMessage(decoded));
    }

    final swap = decoded['swap'] as Map<String, dynamic>;

    return Trade(
      id: swap['id'].toString(),
      from: request.fromCurrency,
      to: request.toCurrency,
      provider: description,
      inputAddress: swap['payinAddress']?.toString(),
      refundAddress: swap['refundAddress']?.toString() ?? request.refundAddress,
      createdAt: DateTime.now(),
      amount: swap['amountFrom']?.toString() ?? request.fromAmount,
      // = amountUserReceives (request.toAmount was derived from our net rate).
      receiveAmount: request.toAmount,
      state: _mapStatus(swap['status']?.toString() ?? 'waiting'),
      payoutAddress: swap['payoutAddress']?.toString(),
      isSendAll: isSendAll,
      toAddressExtraId: request.toAddressExtraId,
    );
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final uri = Uri.https(apiBaseUrl, '$swapsPath/$id');
    final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

    if (response.statusCode == 404) throw TradeNotFoundException(id, provider: description);
    if (response.statusCode != 200)
      throw Exception('GhostSwap: unexpected status ${response.statusCode}');

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final swap = decoded['swap'] as Map<String, dynamic>;

    return Trade(
      id: id,
      from: CryptoCurrency.safeParseCurrencyFromString(swap['from']?.toString() ?? ''),
      to: CryptoCurrency.safeParseCurrencyFromString(swap['to']?.toString() ?? ''),
      provider: description,
      inputAddress: swap['payinAddress']?.toString(),
      amount: swap['amountFrom']?.toString() ?? '',
      state: _mapStatus(swap['status']?.toString() ?? 'waiting'),
      outputTransaction: swap['payoutHash']?.toString(),
      payoutAddress: swap['payoutAddress']?.toString(),
    );
  }

  // ----- helpers -------------------------------------------------------------

  Future<Map<String, dynamic>?> _quote({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required String amountFrom,
    required bool isFixedRateMode,
  }) async {
    final body = {
      'from': _ticker(from),
      'to': _ticker(to),
      'amountFrom': amountFrom,
      'mode': _mode(isFixedRateMode),
    };
    final uri = Uri.https(apiBaseUrl, quotesPath);
    final response =
        await ProxyWrapper().post(clearnetUri: uri, headers: _headers, body: json.encode(body));
    if (response.statusCode != 200) return null;
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final quote = decoded['quote'];
    return quote is Map<String, dynamic> ? quote : null;
  }

  String _mode(bool isFixedRateMode) => isFixedRateMode ? 'fixed' : 'float';

  /// Map a CryptoCurrency to a GhostSwap ticker (lowercase; tokens carry their tag).
  String _ticker(CryptoCurrency currency) {
    switch (currency) {
      case CryptoCurrency.nano:
        return 'xno';
      default:
        return currency.title.toLowerCase();
    }
  }

  /// GhostSwap statuses map 1:1 to Cake TradeStates, except `hold` (AML review),
  /// which is shown as a neutral processing state — never expose screening.
  TradeState _mapStatus(String status) {
    if (status == 'hold') return TradeState.confirming;
    return TradeState.deserialize(raw: status);
  }

  String _errorMessage(Map<String, dynamic> decoded) {
    final error = decoded['error'];
    if (error is Map && error['message'] is String) return error['message'] as String;
    return 'GhostSwap is unable to process this exchange right now.';
  }

  static double? _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// RFC-4122 UUID v4 (no external dependency) for the Idempotency-Key header.
  static String _uuidV4() {
    final rng = Random.secure();
    final b = List<int>.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }
}
