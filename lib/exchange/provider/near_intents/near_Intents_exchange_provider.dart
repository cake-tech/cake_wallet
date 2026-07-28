import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/near_intents/near_intents_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/proxy_wrapper.dart";

class NearIntentsExchangeProvider extends ExchangeProvider {
  NearIntentsExchangeProvider();

  static const apiKey = secrets.nearIntentsBearerToken;
  static const _baseUrl = "1click.chaindefuser.com";
  static const _versionPath = "/v0";
  static const _tokenPath = "/tokens";
  static const _quotePath = "/quote";
  static const _statusPath = "/status";

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
    "LTC": "ltc1qhdwz74m3wuuhppv2mckagqk9e2e49z5j4kucnv",
    "BTC": "bc1qzwdt09dgr5nle2fkv7h5s6axgjqpdyp5g5tumz",
    "DOGE": "D9t7rGQ9mE3hJ2z1w8pGQxkGmKjYwYc8pQ",
    "BCH": "qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a",

    // EVM (same address works for all EVM chains)
    "ETH": "0x1111111111111111111111111111111111111111",
    "BSC": "0x1111111111111111111111111111111111111111",
    "POL": "0x1111111111111111111111111111111111111111",
    "AVAXC": "0x1111111111111111111111111111111111111111",
    "ARB": "0x1111111111111111111111111111111111111111",
    "BASE": "0x1111111111111111111111111111111111111111",

    // Others
    "SOL": "11111111111111111111111111111111",
    "XRP": "rPT1Sjq2YGrBMTttX4GZHjKu9dyfzbpAYe",
    "TRX": "T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb",
    "TON": "UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM9c",
    "XLM": "GA3D5O2W7YQZJQ3H4Y5QW6N7V8X9Z0A1B2C3D4E5F6G7H8I9J0",
    "ADA": "addr1vyc33hdv5vag52f3d8h0qsngu52vm27x28zkzru333jma9gaxd38v",
    "ZEC": "t1VdfFUbyTT7ZSdeEaHuwB7veGD1NXoUhGS",
  };

  String getNearDummyAddress(CryptoCurrency currency) {
    final tag = (currency.tag ?? "").trim().toUpperCase();
    final title = currency.title.toUpperCase();
    final key = tag.isEmpty ? title : tag;
    return kNearDummyAddresses[key] ?? "";
  }

  static final Map<String, String> _headers = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": apiKey,
  };

  static final _supportedTokensList = <NearIntentsToken>[];

  @override
  String get title => "Near Intents";

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  bool get supportsMemoOrDestinationTag => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.nearIntents;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<ExchangeLimits> fetchLimits(
      {required CryptoCurrency from,
      required CryptoCurrency to,
      required bool isFixedRateMode}) async {
    final tokens = await _getSupportedTokens();
    final originToken = currencyToNearAssetId(from, tokens);
    final destinationToken = currencyToNearAssetId(to, tokens);

    if (originToken == null || destinationToken == null) {
      throw Exception(
          'fetchLimits: unsupported currency pair: ${from.title} ${from.tag ?? ''} to ${to.title} ${to.tag ?? ''}');
    }

    return ExchangeLimits();
  }

  @override
  Future<ProviderRate> fetchRate({
    required Money from,
    required CryptoCurrency to,
    required bool isFixedRate,
  }) async {
    final tokens = await _getSupportedTokens();
    final originToken = currencyToNearAssetId(from.currency as CryptoCurrency, tokens);
    final destinationToken = currencyToNearAssetId(to, tokens);

      if (originToken == null || destinationToken == null) {
        throw Exception("fetchRate: Unsupported currency pair");
      }


      final dummyAddrFrom = getNearDummyAddress(from.currency as CryptoCurrency);
      final dummyAddrTo = getNearDummyAddress(to);

      final NearIntentsDepositMode depositMode = _memoRequiredCurrencies.contains(from.currency as CryptoCurrency) ? .memo : .simple;

      final quoteResp = await getSwapQuote(
        dry: true,
        isFixedRateMode: isFixedRate,
        originAsset: originToken.assetId,
        destinationAsset: destinationToken.assetId,
        amount: from.amount,
        depositMode: depositMode,
        refundTo: dummyAddrFrom,
        recipient: dummyAddrTo,
      );


      final quote = quoteResp.quote;
      final amountIn = quote.amountIn;
      final amountOut = quote.amountOut;

      return ProviderRate(provider: description, rate: ExchangeRate.fromAmounts(Money(amountIn, from.currency), Money(amountOut, to)), limits: ExchangeLimits());
  }

  @override
  Future<Trade> createTrade({
    required TradeRequest request,
  }) async {
      final tokens = await _getSupportedTokens();
      final originToken = currencyToNearAssetId(request.depositCurrency, tokens);
      final destinationToken = currencyToNearAssetId(request.payoutCurrency, tokens);

      if (originToken == null || destinationToken == null) {
        throw Exception("Unsupported currency pair");
      }

      final rawAmountStr = request.isFixedRate ? request.depositAmount.cryptoAmount.amount : request
          .payoutAmount.cryptoAmount.amount;

      final NearIntentsDepositMode depositMode =
          _memoRequiredCurrencies.contains(request.depositCurrency) ? .memo : .simple;

      final quoteResp = await getSwapQuote(
        dry: false,
        isFixedRateMode: request.isFixedRate,
        originAsset: originToken.assetId,
        destinationAsset: destinationToken.assetId,
        depositMode: depositMode,
        amount: rawAmountStr,
        refundTo: request.refundAddress,
        recipient: request.payoutAddress.address,
      );


      final quote = quoteResp.quote;


      return Trade(
        id: quote.depositAddress!,
        // Using deposit address as trade ID
        provider: description,
        state: TradeState.created,
        createdAt: DateTime.now(),
        fundingAddress: quote.depositAddress!,
        payoutAddress: request.payoutAddress.address,
        refundAddress: request.refundAddress,
        depositAmount: Money.parse(quote.amountInFormatted, request.depositCurrency),
        payoutAmount: Money.parse(quote.amountOutFormatted, request.payoutCurrency),
        memo: quote.depositMemo,
      );

  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final param = {"depositAddress": id};
    final uri = Uri.https(_baseUrl, "$_versionPath$_statusPath", param);

    final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception(
        "Near Intents fetch trade failed: ${response.statusCode} ${response.body}",
      );
    }

    final data = NearIntentsStatusResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    // final statusRaw = (data['status'] as String?) ?? 'UNKNOWN';
    //
    // final quoteResponse = data['quoteResponse'] as Map<String, dynamic>? ?? {};
    // final quoteRequest = quoteResponse['quoteRequest'] as Map<String, dynamic>? ?? {};
    //
    // final refundTo = quoteRequest['refundTo'] as String? ?? '';
    // final recipient = quoteRequest['recipient'] as String? ?? '';
    //
    final quoteResponse =data.quoteResponse;
    final quoteRequest = quoteResponse.quoteRequest;
    final quote = quoteResponse.quote;

    final from = _nearAssetIdToCurrency(quoteRequest.destinationAsset, await _getSupportedTokens());

    final to = _nearAssetIdToCurrency(quoteRequest.destinationAsset, await _getSupportedTokens());

    return Trade(
      id: id,
      provider: description,
      fundingAddress: quote.depositAddress ?? "",
      payoutAddress: quoteRequest.recipient,
      refundAddress: quoteRequest.refundTo,
      state: data.status.toState,
      txId: data.swapDetails.originChainTxHashes.firstOrNull?.hash,
      extraId: quote.depositMemo,
      isRefund: data.status == .refunded,
      depositAmount: Money.parse(quote.amountInFormatted, from!),
      payoutAmount: Money.parse(quote.amountOutFormatted, to!),
    );
  }

  // Load & cache supported tokens
  Future<List<NearIntentsToken>> _getSupportedTokens() async {
    if (_supportedTokensList.isNotEmpty) {
      return _supportedTokensList;
    }

    final uri = Uri.https(_baseUrl, "$_versionPath$_tokenPath");

    final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception("response code: ${response.statusCode}");
    }

    final data = (json.decode(response.body) as List<dynamic>).map((item) =>
        NearIntentsToken.fromJson(item as Map<String, dynamic>));
    _supportedTokensList
      ..clear()
      ..addAll(data);
    return _supportedTokensList;
  }

  Future<NearIntentsQuoteResponse> getSwapQuote({
    required bool dry,
    required bool isFixedRateMode,
    required String originAsset,
    required String destinationAsset,
    required BigInt amount,
    required String refundTo,
    required String recipient,
    required NearIntentsDepositMode depositMode,
    List<String>? connectedWallets,
    String? sessionId,
    String? virtualChainRecipient,
    String? virtualChainRefundRecipient,
    String? customRecipientMsg,
    DateTime? deadline,
    String? referral,
    int? quoteWaitingTimeMs,
  }) async {
    final NearIntentsSwapType swapType = isFixedRateMode ? .exactOutput : .exactInput;
    final appFees = [
      NearIntentsAppFee(recipient: _appFeeRecipientNearIntents, fee: int.parse(_appFeesNearIntents))
    ];

    final uri = Uri.https(_baseUrl, "$_versionPath$_quotePath");

    final payload = NearIntentsQuoteRequest(dry: dry,
        swapType: swapType,
        slippageTolerance: _slippageTolerance,
        originAsset: originAsset,
        depositType: .originChain,
        destinationAsset: destinationAsset,
        amount: amount,
        refundTo: refundTo,
        refundType: .originChain,
        recipient: recipient,
        recipientType: .destinationChain,
        deadline: deadline??  _buildDeadline(),
depositMode: depositMode,
connectedWallets: connectedWallets,
      sessionId: sessionId,
      virtualChainRecipient: virtualChainRecipient,
      virtualChainRefundRecipient: virtualChainRefundRecipient,
      customRecipientMsg: customRecipientMsg,
      referral: referral,
      quoteWaitingTimeMs: quoteWaitingTimeMs,
        appFees: appFees
    );

      final response = await ProxyWrapper().post(
        clearnetUri: uri,
        headers: _headers,
        body: jsonEncode(payload.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception("Quote request failed with status: ${response.statusCode}");
      }

      return NearIntentsQuoteResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);

  }



  String? _normalizeTagToNearBlockchain(String? tag) => switch (tag) {
      "TRX" => "tron",
      "AVAXC" => "avax",
      _ => tag?.toLowerCase(),
    };

  String? _normalizeNearBlockchainToTag(String? blockchain) => switch (blockchain) {
      "tron" => "TRX",
      "avax" => "AVAXC",
      _ => blockchain?.toUpperCase(),
    };

  NearIntentsToken? currencyToNearAssetId(CryptoCurrency currency, List<NearIntentsToken> supported) {
    if (supported.isEmpty) {
      return null;
    }

    final symbol = currency.title.toUpperCase();
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

  CryptoCurrency? _nearAssetIdToCurrency(String assetId, List<NearIntentsToken> supported) {
    if (supported.isEmpty) {
      return null;
    }

    final token = supported.firstWhereOrNull((t) => t.assetId == assetId);

    if (token == null) {
      return null;
    }

    final title = token.symbol.toUpperCase().replaceAll(RegExp(r"\s*\([^)]*\)"), "");

    final normalizedNetwork = _normalizeNearBlockchainToTag(token.blockchain);

    final isNativeAsset = assetId.contains(":native:coin");

    final tag = isNativeAsset || normalizedNetwork == title ? null : normalizedNetwork;

    return CryptoCurrency.safeParseCurrencyFromString(title, tag: tag);
  }

  DateTime _buildDeadline() => DateTime.now()
        .toUtc()
        .add(const Duration(hours: 2));
}
