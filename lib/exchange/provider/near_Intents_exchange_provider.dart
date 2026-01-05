import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/core/utilities.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_not_created_exception.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/utils/currency_pairs_utils.dart';
import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cake_wallet/utils/exchange_provider_logger.dart';

class NearIntentsExchangeProvider extends ExchangeProvider {
  NearIntentsExchangeProvider()
      : super(pairList: supportedPairs(_notSupported));

  static const List<CryptoCurrency> _notSupported = [];

  static const apiKey = secrets.nearIntentsBearerToken;
  static const _baseUrl = '1click.chaindefuser.com';
  static const _versionPath = '/v0';
  static const _tokenPath = '/tokens';
  static const _quotePath = '/quote';
  static const _statusPath = '/status';

  static const _slippageTolerance = 100; // 1%
  static const _appFeesNearIntents = secrets.nearIntentsAppFee;
  static const _appFeeRecipientNearIntents = secrets.nearIntentsAppFeeRecipient;

  static const _memoRequiredCurrencies = <CryptoCurrency>[
    CryptoCurrency.xrp,
    CryptoCurrency.xlm,
    CryptoCurrency.ton,
  ];

  /// Use these only for quote/rate testing (dummy data).
  static const Map<String, String> kNearDummyAddresses = {
    // UTXO
    'LTC': 'ltc1qhdwz74m3wuuhppv2mckagqk9e2e49z5j4kucnv',
    'BTC': 'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kygt080',
    'ZZEC': 't1Zcash4hPS2bq8rTQkN9bKpZV1X4W3pZxK',
    'DOGE': 'D9t7rGQ9mE3hJ2z1w8pGQxkGmKjYwYc8pQ',
    'BCH': 'qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a',

    // EVM (same address works for all EVM chains)
    'ETH': '0x1111111111111111111111111111111111111111',
    'BSC': '0x1111111111111111111111111111111111111111',
    'POL': '0x1111111111111111111111111111111111111111',
    'AVAXC': '0x1111111111111111111111111111111111111111',
    'ARB': '0x1111111111111111111111111111111111111111',
    'BASE': '0x1111111111111111111111111111111111111111',

    // Others
    'SOL': '11111111111111111111111111111111',
    'XRP': 'rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpAYe',
    'TRX': 'T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb',
    'TON': 'UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM9c',
    'XLM': 'GA3D5O2W7YQZJQ3H4Y5QW6N7V8X9Z0A1B2C3D4E5F6G7H8I9J0',
    'ADA': 'addr1vyc33hdv5vag52f3d8h0qsngu52vm27x28zkzru333jma9gaxd38v',
  };

  String getNearDummyAddress(CryptoCurrency currency) {
    final tag = (currency.tag ?? '').trim().toUpperCase();
    final title = currency.title.toUpperCase();
    final key = tag.isEmpty ? title : tag;
    return kNearDummyAddresses[key] ?? '';
  }

  static final Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': '$apiKey',
  };

  static final _supportedTokensList = <Token>[];

  @override
  String get title => 'Near Intents';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.nearIntents;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Limits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode}) async {
    final tokens = await _geSupportedTokens();
    final originToken = currencyToNearAssetId(from, tokens);
    final destinationToken = currencyToNearAssetId(to, tokens);

    if (originToken == null || destinationToken == null) {
      throw Exception(
          'fetchLimits: unsupported currency pair: ${from.title} ${from.tag ?? ''} to ${to.title} ${to.tag ?? ''}');
    }

    return Limits(min: null, max: null);
  }

  @override
  Future<double> fetchRate({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required double amount,
    required bool isFixedRateMode,
    required bool isReceiveAmount,
  }) async {
    final tokens = await _geSupportedTokens();
    final originToken = currencyToNearAssetId(from, tokens);
    final destinationToken = currencyToNearAssetId(to, tokens);

    try {
      if (originToken == null || destinationToken == null) {
        throw Exception('fetchRate: Unsupported currency pair');
      }

      final formattedAmount = AmountConverter.toBaseUnits(amount.toString(),
          isFixedRateMode ? destinationToken.decimals : originToken.decimals);

      final dummyAddrFrom = getNearDummyAddress(from);
      final dummyAddrTo = getNearDummyAddress(to);

      final depositMode = _memoRequiredCurrencies.contains(from) ? "MEMO" : "SIMPLE";

      final quote = await getSwapQuote(
        dry: true,
        isFixedRateMode: isFixedRateMode,
        originAsset: originToken.assetId,
        destinationAsset: destinationToken.assetId,
        amount: formattedAmount,
        depositMode: depositMode,
        refundTo: dummyAddrFrom,
        recipient: dummyAddrTo,
      );

      if (quote == null) {
        throw Exception('fetchRate: Quote returned null');
      }

      final q = quote['quote'] as Map<String, dynamic>;
      final amountIn =
          double.tryParse(q['amountInFormatted']?.toString() ?? '0') ?? 0.0;
      final amountOut =
          double.tryParse(q['amountOutFormatted']?.toString() ?? '0') ?? 0.0;

      if (amountIn == 0) return 0.0;

      final rate = amountOut / amountIn;

      ExchangeProviderLogger.logSuccess(
        provider: description,
        function: 'fetchRate',
        requestData: {
          'from': from.title,
          'to': to.title,
          'amount': amount,
          'formattedAmount': formattedAmount,
          'isFixedRateMode': isFixedRateMode,
          'isReceiveAmount': isReceiveAmount,
          'originAsset': originToken.assetId,
          'destinationAsset': destinationToken.assetId,
        },
        responseData: {
          'amountIn': amountIn,
          'amountOut': amountOut,
          'rate': rate,
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
    try {
      final tokens = await _geSupportedTokens();
      final originToken = currencyToNearAssetId(request.fromCurrency, tokens);
      final destinationToken =
          currencyToNearAssetId(request.toCurrency, tokens);

      if (originToken == null || destinationToken == null) {
        throw Exception('Unsupported currency pair');
      }

      final rawAmountStr =
          isFixedRateMode ? request.toAmount : request.fromAmount;

      final baseAmount = AmountConverter.toBaseUnits(
        rawAmountStr,
        isFixedRateMode
            ? request.toCurrency.decimals
            : request.fromCurrency.decimals,
      );

      final depositMode = _memoRequiredCurrencies.contains(request.fromCurrency) ? "MEMO" : "SIMPLE";

      final quote = await getSwapQuote(
        dry: false,
        isFixedRateMode: isFixedRateMode,
        originAsset: originToken.assetId,
        destinationAsset: destinationToken.assetId,
        depositMode: depositMode,
        amount: baseAmount,
        refundTo: request.refundAddress,
        recipient: request.toAddress,
      );

      if (quote == null) {
        throw Exception('Quote request failed');
      }

      final quoteObj = quote['quote'] as Map<String, dynamic>;
      final depositAddress = quoteObj['depositAddress'] as String;
      final depositMemo = quoteObj['depositMemo'] as String?;

      final quoteRequest = quote['quoteRequest'] as Map<String, dynamic>;
      final fromAssetId = quoteRequest['originAsset'] as String;
      final toAssetId = quoteRequest['destinationAsset'] as String;

      final fromCurrency = _nearAssetIdToCurrency(fromAssetId, tokens);
      if (fromCurrency == null) {
        throw Exception('Failed to parse from currency from assetId: $fromAssetId');
      }

      final toCurrency = _nearAssetIdToCurrency(toAssetId, tokens);
      if (toCurrency == null) {
        throw Exception('Failed to parse to currency from assetId: $toAssetId');
      }

      final from = CryptoCurrency.safeParseCurrencyFromString(fromCurrency.$1,
          tag: fromCurrency.$2);
      final to = CryptoCurrency.safeParseCurrencyFromString(toCurrency.$1,
          tag: toCurrency.$2);


      final trade = Trade(
        id: depositAddress,
        // Using deposit address as trade ID
        from: from,
        to: to,
        provider: description,
        providerName: title,
        state: TradeState.created,
        createdAt: DateTime.now(),
        inputAddress: depositAddress,
        payoutAddress: request.toAddress,
        refundAddress: request.refundAddress,
        amount: request.fromAmount,
        receiveAmount: quoteObj['amountOutFormatted']?.toString(),
        memo: depositMemo,
        isSendAll: isSendAll,
        userCurrencyFromRaw:
            '${request.fromCurrency.title}_${request.fromCurrency.tag ?? ''}',
        userCurrencyToRaw:
            '${request.toCurrency.title}_${request.toCurrency.tag ?? ''}',
      );

      ExchangeProviderLogger.logSuccess(
        provider: description,
        function: 'createTrade',
        requestData: {
          'from': request.fromCurrency.title,
          'to': request.toCurrency.title,
          'fromAmount': request.fromAmount,
          'toAmount': request.toAmount,
          'refundAddress': request.refundAddress,
          'recipient': request.toAddress,
          'isFixedRateMode': isFixedRateMode,
          'isSendAll': isSendAll,
          'originAsset': originToken.assetId,
          'destinationAsset': destinationToken.assetId,
        },
        responseData: {
          'correlationId': quote['correlationId'],
          'depositAddress': depositAddress,
          'depositMemo': depositMemo,
          'quote': quoteObj,
        },
      );

      return trade;
    } catch (e, s) {
      ExchangeProviderLogger.logError(
        provider: description,
        function: 'createTrade',
        error: e,
        stackTrace: s,
        requestData: {
          'from': request.fromCurrency.title,
          'to': request.toCurrency.title,
          'fromAmount': request.fromAmount,
          'toAmount': request.toAmount,
          'refundAddress': request.refundAddress,
          'recipient': request.toAddress,
          'isFixedRateMode': isFixedRateMode,
          'isSendAll': isSendAll,
        },
      );
      throw TradeNotCreatedException(description, description: e.toString());
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final param = {'depositAddress': id};
    final uri = Uri.https(_baseUrl, '$_versionPath$_statusPath', param);

    final response =
        await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception(
        'Near Intents fetch trade failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final statusRaw = (data['status'] as String?) ?? 'UNKNOWN';

    final quoteResponse = data['quoteResponse'] as Map<String, dynamic>? ?? {};
    final quoteRequest =
        quoteResponse['quoteRequest'] as Map<String, dynamic>? ?? {};

    final refundTo = quoteRequest['refundTo'] as String? ?? '';
    final recipient = quoteRequest['recipient'] as String? ?? '';

    // Parsing 'from' currency
    final originAssetId = quoteRequest['originAsset'] as String? ?? '';
    final from =
        _nearAssetIdToCurrency(originAssetId, await _geSupportedTokens());

    CryptoCurrency? coinFrom;
    CryptoCurrency? coinTo;

    if (from != null) {
      coinFrom = CryptoCurrency.safeParseCurrencyFromString(from.$1, tag: from.$2);
    }

    // Parsing 'to' currency
    final destinationAssetId =
        quoteRequest['destinationAsset'] as String? ?? '';

    final to =
        _nearAssetIdToCurrency(destinationAssetId, await _geSupportedTokens());

    if (to != null) {
      coinTo = CryptoCurrency.safeParseCurrencyFromString(to.$1, tag: to.$2);
    }

    final quote = quoteResponse['quote'] as Map<String, dynamic>? ?? {};
    final swap = data['swapDetails'] as Map<String, dynamic>? ?? {};

    final depositAddress = quote['depositAddress'] as String?;
    final depositMemo = quote['depositMemo'] as String?;

    final depositAmount = swap['amountInFormatted']?.toString() ??
        quote['amountInFormatted']?.toString() ??
        '0';

    final receiveAmount = swap['amountOutFormatted']?.toString() ??
        quote['amountOutFormatted']?.toString();

    final originTxHash = (swap['originChainTxHashes'] as List?)
        ?.firstOrNull?['hash']
        ?.toString();

    return Trade(
      id: id,
      from: coinFrom,
      to: coinTo,
      provider: description,
      inputAddress: depositAddress,
      payoutAddress: recipient,
      refundAddress: refundTo,
      amount: depositAmount,
      receiveAmount: receiveAmount,
      state: _normalizeStatusToTradeState(statusRaw),
      txId: originTxHash,
      extraId: depositMemo,
      isRefund: statusRaw == 'REFUNDED',
      userCurrencyFromRaw: '${from?.$1.toUpperCase()}' + '_' + '${from?.$2?.toUpperCase() ?? ''}',
      userCurrencyToRaw: '${to?.$1.toUpperCase()}' + '_' + '${to?.$2?.toUpperCase() ?? ''}',
    );
  }

  // Load & cache supported tokens
  Future<List<Token>> _geSupportedTokens() async {
    if (_supportedTokensList.isNotEmpty) return _supportedTokensList;

    try {
      final uri = Uri.https(_baseUrl, '$_versionPath$_tokenPath');

      final response =
          await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as List<dynamic>;
      _supportedTokensList
        ..clear()
        ..addAll(data.map((e) => Token.fromJson(e as Map<String, dynamic>)));
      return _supportedTokensList;
    } catch (e) {
      printV(e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSwapQuote({
    required bool dry,
    required bool isFixedRateMode,
    required String originAsset,
    required String destinationAsset,
    required String amount,
    required String refundTo,
    required String recipient,
    required String depositMode,
    List<String>? connectedWallets,
    String? sessionId,
    String? virtualChainRecipient,
    String? virtualChainRefundRecipient,
    String? customRecipientMsg,
    String? deadline,
    String? referral,
    int? quoteWaitingTimeMs,
  }) async {
    final swapType = isFixedRateMode ? 'EXACT_OUTPUT' : 'EXACT_INPUT';
    final _isoUtcDeadline = _buildDeadline();
    final appFees = [
      {
        "recipient": _appFeeRecipientNearIntents,
        "fee": _appFeesNearIntents,
      }
    ];

    final uri = Uri.https(_baseUrl, "$_versionPath$_quotePath");

    final payload = {
      "dry": dry,
      "depositMode": depositMode,
      "swapType": swapType,
      "slippageTolerance": _slippageTolerance,
      "originAsset": originAsset,
      "depositType": 'ORIGIN_CHAIN',
      "destinationAsset": destinationAsset,
      "amount": amount,
      "refundTo": refundTo,
      "refundType": 'ORIGIN_CHAIN',
      "recipient": recipient,
      "recipientType": 'DESTINATION_CHAIN',
      "deadline": _isoUtcDeadline,
      if (connectedWallets != null) "connectedWallets": connectedWallets,
      if (sessionId != null) "sessionId": sessionId,
      if (virtualChainRecipient != null)
        "virtualChainRecipient": virtualChainRecipient,
      if (virtualChainRefundRecipient != null)
        "virtualChainRefundRecipient": virtualChainRefundRecipient,
      if (customRecipientMsg != null) "customRecipientMsg": customRecipientMsg,
      if (deadline != null) "deadline": deadline,
      if (referral != null) "referral": referral,
      if (quoteWaitingTimeMs != null) "quoteWaitingTimeMs": quoteWaitingTimeMs,
      "appFees": appFees,
    };

    try {
      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode != 201) {
        printV("Quote request failed with status: ${response.statusCode}");
        return null;
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      printV("Quote error: $e");
      return null;
    }
  }

  TradeState _normalizeStatusToTradeState(String status) {
    return switch (status.toUpperCase()) {
      'PENDING_DEPOSIT' => TradeState.pending,
      'PROCESSING' => TradeState.processing,
      'SUCCESS' => TradeState.success,
      'INCOMPLETE_DEPOSIT' => TradeState.underpaid,
      'REFUNDED' => TradeState.refunded,
      'FAILED' => TradeState.failed,
      _ => TradeState.notFound,
    };
  }

  String _normalizeTitleToNearSymbol(CryptoCurrency currency) {
    final title = currency.title.toUpperCase();
    return switch (title) {
      'TZEC' => 'ZEC',
      _ => title,
    };
  }

  String? _normalizeTagToNearBlockchain(String? tag) {
    return switch (tag) {
      'TRX' => 'tron',
      'AVAXC' => 'avax',
      _ => tag?.toLowerCase(),
    };
  }

  String? _normalizeNearBlockchainToTag(String? blockchain) {
    return switch (blockchain) {
      'tron' => 'TRX',
      'avax' => 'AVAXC',
      _ => blockchain?.toUpperCase(),
    };
  }

  Token? currencyToNearAssetId(CryptoCurrency currency, List<Token> supported) {
    if (supported.isEmpty) return null;

    final symbol = _normalizeTitleToNearSymbol(currency).toUpperCase();
    final blockchain = _normalizeTagToNearBlockchain(currency.tag);

    // Native asset (no contract)
    final native = supported.firstWhereOrNull((t) =>
        t.symbol.toUpperCase() == symbol &&
        (blockchain == null || t.blockchain.toLowerCase() == blockchain) &&
        t.contractAddress == null);

    if (native != null) {
      return native;
    }

    final token = supported.firstWhereOrNull((t) =>
        t.symbol.toUpperCase() == symbol &&
        (blockchain == null || t.blockchain.toLowerCase() == blockchain));

    return token;
  }

  (String, String?)? _nearAssetIdToCurrency(
      String assetId, List<Token> supported) {
    if (supported.isEmpty) return null;

    final token = supported.firstWhereOrNull((t) => t.assetId == assetId);

    if (token == null) return null;
    final title = token.symbol;
    final normalizedNetwork = _normalizeNearBlockchainToTag(token.blockchain);
    final tag =
        normalizedNetwork == title.toUpperCase() ? null : normalizedNetwork;

    return (title, tag);
  }

  String _buildDeadline() {
    return DateTime.now()
        .toUtc()
        .add(const Duration(hours: 2))
        .toIso8601String()
        .replaceFirst(RegExp(r'\.\d+Z$'), 'Z');
  }
}

class Token {
  final String assetId;
  final int decimals;
  final String blockchain;
  final String symbol;
  final double priceUsd;
  final String priceUpdatedAt;
  final String? contractAddress;

  Token({
    required this.assetId,
    required this.decimals,
    required this.blockchain,
    required this.symbol,
    required this.priceUsd,
    required this.priceUpdatedAt,
    required this.contractAddress,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    final decimals = json['decimals'] as int?;
    if (decimals == null) {
      throw Exception('Token decimals is null for assetId: ${json['assetId']}');
    }
    return Token(
      assetId: json['assetId'] as String,
      decimals: json['decimals'] as int,
      blockchain: json['blockchain'] as String,
      symbol: json['symbol'] as String,
      priceUsd: (json['price'] as num?)?.toDouble() ?? 0.0,
      priceUpdatedAt: json['priceUpdatedAt'] as String,
      contractAddress: json['contractAddress'] as String?,
    );
  }
}
