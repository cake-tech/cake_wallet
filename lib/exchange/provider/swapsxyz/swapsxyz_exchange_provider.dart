import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:json_annotation/json_annotation.dart";




class SwapsXyzTrade extends RoutableTrade {
  SwapsXyzTrade({
    required this.needToRegister, required this.sourceTokenAddress, required this.sourceTokenDecimals, required this.sourceTokenAmountRaw, required this.requiresTokenApproval, required super.fundingAddress,
    required super.state,
    required super.depositAmount,
    required super.payoutAmount,
    required super.id,
    required super.provider,
    required super.payoutAddress,
    required super.refundAddress,

    required super.routerData,
    required super.routerValue,
    super.router,
    super.createdAt,
    super.expiredAt,
    super.extraId,
    super.outputTransaction,
    super.walletId,
    super.toAddressExtraId,
    super.password,
    super.providerId,
    super.memo,
    super.txId,
    super.isRefund,
  }) : super();

  // final trade = Trade(
  //   needToRegisterInSwapXyz: needToRegisterInSwapXyz,
  //   sourceTokenAddress: srcTokenAddr ?? srcToken,
  //   sourceTokenDecimals: srcTokenDecs,
  //   sourceTokenAmountRaw: reqAmountRaw,
  //   requiresTokenApproval: requiresTokenApproval,
  // );
  final bool needToRegister;
  final String sourceTokenAddress;
  final int sourceTokenDecimals;
  final String sourceTokenAmountRaw;
  final bool requiresTokenApproval;
}

class SwapsXyzExchangeProvider extends ExchangeProvider {
  SwapsXyzExchangeProvider();

  static final List<CryptoCurrency> _notSupportedAsSourceToken = [
    CryptoCurrency.sol,
    ...CryptoCurrency.all.where(
      (c) => (c.tag ?? "").toUpperCase() == "SOL" || c.tag == CryptoCurrency.bnb.tag,
    ),
  ];

  static const _transferSig = "0xa9059cbb";
  static const _swapAndExecuteSig = "0x9be111d1";

  static const _apiKey = secrets.swapsXyzApiKey;
  static const _baseUrl = "api-v2.swaps.xyz";
  static const _getChainList = "api/getChainList";
  static const _getPaths = "api/getPaths";
  static const _getQuotePaths = "api/getQuote";
  static const _getAction = "api/getAction";
  static const _registerTxs = "api/registerTxs";
  static const _getStatus = "api/getStatus";

  static final _headers = {"x-api-key": _apiKey};

  static final _supportedChainList = <SwapsXyzChain>[];
  final Map<int, List<TokenPathInfo>> _tokensCache = {};

  @override
  String get title => "Swaps.XYZ";

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => false;

  @override
  bool get supportsMemoOrDestinationTag => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.swapsXyz;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<ExchangeLimits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    final chains = await _getSupportedChains();
    if (chains.isEmpty) {
      throw Exception("Failed to fetch supported chains");
    }

    final fromToUse = isFixedRateMode ? to : from;
    final toToUse = isFixedRateMode ? from : to;

    final srcChain = _findChainByCurrency(fromToUse, chains);
    final dstChain = _findChainByCurrency(toToUse, chains);

    await _ensureTokensCached(fromChain: srcChain, toChain: dstChain, from: fromToUse, to: toToUse);

    final srcToken = _getTokenAddress(currency: fromToUse, chain: srcChain);
    final dstToken = _getTokenAddress(currency: toToUse, chain: dstChain);

    final params = SwapsXyzPathsRequest(
      srcChainId: srcChain.chainId.toString(),
      srcToken: srcToken,
      dstChainId: dstChain.chainId.toString(),
      dstToken: dstToken,
    );

    final uri = Uri.https(_baseUrl, _getPaths, params.toJson());
    final res = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception("Unexpected http status: ${res.statusCode}");
    }

    final body = SwapsXyzPathsResponse.fromJson(json.decode(res.body) as Map<String, dynamic>);

    if (body.paths.isEmpty) {
      throw Exception("No paths for ${fromToUse.title} -> ${toToUse.title}");
    }

    final int requestedDstId = dstChain.chainId;

    SwapsXyzChainPath? path = body.paths.firstWhereOrNull((p) => p.chainId == requestedDstId);

    path ??= body.paths.firstWhere(
      (p) => (p.tokens is List) || p.amountLimits != null,
      orElse: () => body.paths.first,
    );

    if (isFixedRateMode && !path.supportsExactAmountOut) {
      throw Exception("This route does not support fixed receive (exact-amount-out)");
    }
    if (!isFixedRateMode && !path.supportsExactAmountIn) {
      throw Exception("This route does not support exact send (exact-amount-in)");
    }

    if (isFixedRateMode) {
      final tokensField = path.tokens;

      if (tokensField is List && tokensField.isNotEmpty) {
        final tokens = tokensField.tokens!;
        final wantSym = _normalizeCakeNativeTokenName(toToUse.title).toUpperCase();
        final wantAddr = dstToken.toLowerCase();

        final match = tokens.firstWhereOrNull((t) {
          final sym = t.symbol.toUpperCase();
          final addr = t.address.toLowerCase();
          return sym == wantSym || (addr.isNotEmpty && addr == wantAddr);
        });

        if (match != null) {
          return ExchangeLimits(
            min: Money.tryParse(match.minAmount, from),
            max: Money.tryParse(match.maxAmount, from),
          );
        }
      }
    }
    return ExchangeLimits(
      min: Money.tryParse(path.amountLimits?.minAmount, from),
      max: Money.tryParse(path.amountLimits?.maxAmount, from),
    );
  }

  Future<_PathInfo?> _pickPath({
    required int srcChainId,
    required String srcToken,
    required int dstChainId,
    required String dstToken,
  }) async {
    final uri = Uri.https(_baseUrl, _getPaths, {
      "srcChainId": "$srcChainId",
      "srcToken": srcToken,
      "dstChainId": "$dstChainId",
      "dstToken": dstToken,
    });
    final res = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
    if (res.statusCode != 200) {
      return null;
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final paths = (body["paths"] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (paths.isEmpty) {
      return null;
    }
    final p = paths.first;
    return _PathInfo(
      supportsExactOut: p["supportsExactAmountOut"] == true,
      minToAmountHuman: (p["amountLimits"]?["minAmount"] as String?) ?? "0",
    );
  }

  @override
  Future<ProviderRate> fetchRate({
    required Money from,
    required CryptoCurrency to,
    required bool isFixedRate,
  }) async {
    if (_notSupportedAsSourceToken.contains(from.currency as CryptoCurrency) || _notSupportedAsSourceToken.contains(to)) {
      throw Exception("fetchRate: source token ${from.currency.symbol} is not supported as source token");
    }

    final chains = await _getSupportedChains();
    if (chains.isEmpty) {
      throw Exception("chains.isEmpty");
    }

    final srcChain = _findChainByCurrency(from.currency as CryptoCurrency, chains);
    final dstChain = _findChainByCurrency(to, chains);

    await _ensureTokensCached(
      fromChain: srcChain,
      toChain: dstChain,
      from: from.currency as CryptoCurrency,
      to: to,
    );

    final srcToken = _getTokenAddress(currency: from.currency as CryptoCurrency, chain: srcChain);
    final dstToken = _getTokenAddress(currency: to, chain: dstChain);

    if (isFixedRate) {
      final path = await _pickPath(
        srcChainId: srcChain.chainId,
        srcToken: srcToken,
        dstChainId: dstChain.chainId,
        dstToken: dstToken,
      );
      if (path == null || !path.supportsExactOut) {
        throw Exception(
          "fetchRate: route does not support exact-amount-out for ${from.currency.symbol} -> ${to.title}",
        );
      }
    }

    final params = SwapsXyzQuoteRequest(
      srcChainId: srcChain.chainId.toString(),
      srcToken: srcToken,
      dstChainId: dstChain.chainId.toString(),
      dstToken: dstToken,
      amount: from.toString(),
      swapDirection: .exactAmountIn,
    );

    final uri = Uri.https(_baseUrl, _getQuotePaths, params.toJson());
    final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception("fetchRate failed: ${response.body}");
    }

    final data = SwapsXyzQuote.fromJson(json.decode(response.body) as Map<String, dynamic>);
    return ProviderRate(provider: description,
        rate: ExchangeRate(base: from.currency, quote: Money.parse(data.exchangeRate, to),),
        limits: await fetchLimits(
            from: from.currency as CryptoCurrency, to: to, isFixedRateMode: isFixedRate));
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    final sender = request.refundAddress.trim();
    final recipient = request.payoutAddress.address.trim();
    if (sender.isEmpty || recipient.isEmpty) {
      throw Exception("Sender (refundAddress) or recipient (toAddress) is empty");
    }

    final chains = await _getSupportedChains();
    if (chains.isEmpty) {
      throw Exception("Failed to fetch supported chains");
    }
    final srcChain = _findChainByCurrency(request.depositCurrency, chains);
    final dstChain = _findChainByCurrency(request.payoutCurrency, chains);

    await _ensureTokensCached(
      fromChain: srcChain,
      toChain: dstChain,
      from: request.depositCurrency,
      to: request.payoutCurrency,
    );

    final srcToken = _getTokenAddress(currency: request.depositCurrency, chain: srcChain);
    final dstToken = _getTokenAddress(currency: request.payoutCurrency, chain: dstChain);

    final amount = request.isFixedRate
        ? request.depositAmount.cryptoAmount
        : request.payoutAmount.cryptoAmount;

    final params = SwapsXyzActionRequest(
      actionType: .swapAction,
      sender: sender,
      srcChainId: srcChain.chainId.toString(),
      srcToken: srcToken,
      dstChainId: dstChain.chainId.toString(),
      dstToken: dstToken,
      slippage: "300",
      swapDirection: request.isFixedRate ? .exactAmountOut : .exactAmountIn,
      amount: amount.amount.toString(),
      recipient: recipient,
    );

    final uri = Uri.https(_baseUrl, _getAction, params.toJson());
    final res = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception("getAction failed: ${res.statusCode} ${res.body}");
    }

    final data = SwapsXyzActionResponse.fromJson(json.decode(res.body) as Map<String, dynamic>);

    final txId = data.txId;

    final vmId = data.vmId;
    final txObj = data.tx;

    final txTo = txObj["to"]?.toString();
    final chainId = txObj["chainId"]?.toString();
    final routerData = txObj["data"]?.toString();

    // Allow only:
    // - null (native / deposit-address flow)
    // - '0x' (no call data)
    // - ERC20 transfer(0xa9059cbb) selector
    // - swapAndExecute(0x9be111d1) selector
    final isAllowed =
        routerData == null ||
        routerData == "0x" ||
        _decodeMethodSelector(routerData) == _transferSig ||
        _decodeMethodSelector(routerData) == _swapAndExecuteSig;

    if (!isAllowed) {
      throw Exception("Does not support that method selector");
    }

    final txValue = txObj["value"]?.toString() ?? "0";

    final bridgeIds = data.bridgeIds ?? [];
    if (txId.isEmpty) {
      throw Exception("No txId returned by getAction");
    }

    // final amtIn = (data['amountIn'] as Map?) ?? const {};
    // final amtInMax = (data['amountInMax'] as Map?) ?? const {};
    // final srcTokenAddr = amtIn['address']?.toString();
    // final srcTokenDecs = (amtIn['decimals'] as num?)?.toInt() ?? request.fromCurrency.decimals;
    // final requiresTokenApproval = data['requiresTokenApproval'] as bool? ?? false;

    // final reqAmountStr = (amtInMax['amount'] ?? amtIn['amount'])?.toString() ?? '0';
    // final reqAmountRaw = reqAmountStr.replaceAll('n', '');

    final needToRegisterInSwapXyz =
        vmId == .altVm ||
        bridgeIds.contains("alt-vm") ||
        chainId == "solana" ||
        bridgeIds.contains("solana");

    return SwapsXyzTrade(
      state: TradeState.created,
      depositAmount: request.depositAmount.cryptoAmount,
      payoutAmount: request.payoutAmount.cryptoAmount,
      fundingAddress: txTo??"",
      createdAt: DateTime.now(),
      id: txId,
      provider: description,
      payoutAddress: request.payoutAddress.address,
      refundAddress: request.refundAddress,
      routerData: routerData ?? "",
      routerValue: txValue,
      router: chainId,
      providerId: vmId.name,
      needToRegister: needToRegisterInSwapXyz,
      sourceTokenAddress: data.amountIn.address,
      sourceTokenDecimals: data.amountIn.decimals,
      sourceTokenAmountRaw: data.amountInMax.amount.toString(),
      requiresTokenApproval: data.requiresTokenApproval,

    );
  }

  /// Register a broadcasted tx with Swaps.xyz (required for alt-vm).
  static Future<bool> registerAltVmTx({
    required String txId,
    required String txHash,
    required int chainId,
    required String vmId,
  }) async {
    try {
      final uri = Uri.https(_baseUrl, _registerTxs);
      final payload = {"txId": txId, "vmId": vmId, "txHash": txHash, "chainId": chainId};

      final res = await ProxyWrapper().post(
        clearnetUri: uri,
        headers: {..._headers, "content-type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode != 200) {
        printV("registerTxs failed: ${res.statusCode} ${res.body}");
        return false;
      }
      final List<dynamic> body = json.decode(res.body) as List<dynamic>;
      if (body.isEmpty) {
        return false;
      }

      final isSuccess = (body[0] as Map<String, dynamic>)["success"] as bool? ?? false;

      return isSuccess;
    } catch (e) {
      printV("registerAltVmTx error: $e");
      return false;
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    final uri = Uri.https(_baseUrl, _getStatus, {"txId": id});
    final resp = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

    if (resp.statusCode != 200) {
      throw Exception("getStatus failed: ${resp.statusCode} ${resp.body}");
    }


    final SwapsXyzTxDetails data;
    try {
      data = SwapsXyzTxDetails.fromJson(json.decode(resp.body) as Map<String, dynamic>);
    } on CheckedFromJsonException {
final error = SwapsXyzError.fromJson(json.decode(resp.body) as Map<String, dynamic>);
throw Exception(error);
    }



    final status = data.status.toState;
    final refundAddress = data.sender.toString();

    final srcTransaction = data.srcTx;
    final dstTransaction = data.dstTx;

    final inputAddress = srcTransaction?.toAddress;


    final srcPaymentToken = srcTransaction?.paymentToken;
    final dstPaymentToken = dstTransaction?.paymentToken;

    final fromSymbol = srcPaymentToken?.symbol ?? "";
    final toSymbol = dstPaymentToken?.symbol ?? "";

    CryptoCurrency? toCurrency;
    if (toSymbol.isNotEmpty) {
      toCurrency = CryptoCurrency.safeParseCurrencyFromString(toSymbol);
    }


    final txHash = srcTransaction?.txHash;

    // Minimal-unit amounts like "12000n"
    final srcAmountRaw = srcPaymentToken?.amount;
    final dstAmountRaw = dstPaymentToken?.amount;

    final fromCurrency = CryptoCurrency.safeParseCurrencyFromString(fromSymbol);

    // Timestamps can be num or "123n"  handle both
    final srcTs = srcTransaction?.timestamp;
    final dstTs =dstTransaction?.timestamp;
    final timestamp = srcTs ?? dstTs;


    return SwapsXyzTrade(
      id: data.txId,
      provider: description,
      fundingAddress: inputAddress ?? "",
      payoutAddress: dstTransaction?.toAddress ?? "",
      txId: txHash,
      state: status,
      createdAt: timestamp,
      refundAddress: refundAddress,
      needToRegister: false,
      sourceTokenAddress: srcPaymentToken?.address ?? "",
      sourceTokenDecimals: srcPaymentToken?.decimals ?? 0,
      sourceTokenAmountRaw: srcPaymentToken?.amount.toString() ?? "",
      requiresTokenApproval: false,
      depositAmount: Money(srcAmountRaw ?? BigInt.zero, fromCurrency!),
      payoutAmount: Money(dstAmountRaw ?? BigInt.zero, toCurrency!),
      routerData: "",
      routerValue: "",
    );
  }

  // Load & cache supported chains once
  Future<List<SwapsXyzChain>> _getSupportedChains() async {
    if (_supportedChainList.isNotEmpty) {
      return _supportedChainList;
    }
    try {
      final uri = Uri.https(_baseUrl, _getChainList);
      final response = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body) as List<dynamic>;
      _supportedChainList
        ..clear()
        ..addAll(data.map((e) => SwapsXyzChain.fromJson(e as Map<String, dynamic>)));
      return _supportedChainList;
    } catch (e) {
      printV(e);
      return [];
    }
  }

  Future<void> _ensureTokensCached({
    required SwapsXyzChain fromChain,
    required SwapsXyzChain toChain,
    required CryptoCurrency from,
    required CryptoCurrency to,
  }) async {
    final needSrc =
        !_tokensCache.containsKey(fromChain.chainId) ||
        (_tokensCache[fromChain.chainId]?.isEmpty ?? true);

    final needDst =
        !_tokensCache.containsKey(toChain.chainId) ||
        (_tokensCache[toChain.chainId]?.isEmpty ?? true);

    if (!needSrc && !needDst) {
      return;
    }

    if (needSrc) {
      await _fetchAndCacheTokens(srcChainId: fromChain.chainId);
    }
    if (needDst) {
      await _fetchAndCacheTokens(srcChainId: toChain.chainId);
    }
  }

  // call getPaths and merge tokens into cache keyed by the chainId
  Future<void> _fetchAndCacheTokens({required int srcChainId}) async {
    final params = <String, String>{
      "srcChainId": "$srcChainId",
      "srcToken": "0x0000000000000000000000000000000000000000",
      // Native placeholder
    };

    final uri = Uri.https(_baseUrl, _getPaths, params);
    final res = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
    if (res.statusCode != 200) {
      printV("getPaths failed: ${res.statusCode} ${res.body}");
      return;
    }

    Map<String, dynamic> body;
    try {
      body = json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      printV("getPaths JSON decode error: $e");
      return;
    }

    // Always cache the source chain's native token (from body['srcToken'])
    final srcTokenJson = body["srcToken"] as Map<String, dynamic>?;
    if (srcTokenJson != null) {
      final symbol = (srcTokenJson["symbol"] as String? ?? "").toUpperCase();
      if (symbol.isNotEmpty) {
        final isNative = srcTokenJson["isNative"] == true;
        final decimals = (srcTokenJson["decimals"] as num?)?.toInt();
        // Treat native token as address = null so _getTokenAddress() emits zero-address
        final addr = isNative ? null : (srcTokenJson["address"] as String?);
        _mergeCache(srcChainId, [
          TokenPathInfo(
            symbol: symbol,
            address: addr,
            decimals: decimals,
            minAmount: srcTokenJson["minAmount"]?.toString(),
            maxAmount: srcTokenJson["maxAmount"]?.toString(),
          ),
        ]);
      }
    }

    final paths = (body["paths"] as List?) ?? const [];
    if (paths.isEmpty) {
      return;
    }

    for (final path in paths) {
      final map = path as Map<String, dynamic>;
      final pathChainId = (map["chainId"] as num?)?.toInt();
      if (pathChainId == null) {
        continue;
      }

      final tokensField = map["tokens"];

      // Case 1: String "all" -> cache empty list to indicate all tokens supported
      if (tokensField is String) {
        if (tokensField.toLowerCase() == "all") {
          _tokensCache[pathChainId] = _tokensCache[pathChainId] ?? <TokenPathInfo>[];
        }
        continue;
      }

      // Case 2: List -> parse and merge
      if (tokensField is List) {
        final parsed = <TokenPathInfo>[];
        for (final token in tokensField) {
          if (token is Map<String, dynamic>) {
            try {
              parsed.add(TokenPathInfo.fromJson(token));
            } catch (e) {
              printV("Token parse error on chain $pathChainId: $e : $token");
            }
          }
        }
        if (parsed.isNotEmpty) {
          _mergeCache(pathChainId, parsed);
        }
      }
    }
  }

  // Merge by symbol, prefer entries that have a non-empty address/decimals
  void _mergeCache(int chainId, List<TokenPathInfo> incoming) {
    final existing = _tokensCache[chainId] ?? const <TokenPathInfo>[];
    final bySymbol = <String, TokenPathInfo>{for (final t in existing) t.symbol: t};

    for (final t in incoming) {
      final cur = bySymbol[t.symbol];
      if (cur == null) {
        bySymbol[t.symbol] = t;
      } else {
        // If incoming has a real address/decimals, prefer it
        final hasBetterAddr =
            (t.address != null && t.address!.isNotEmpty) &&
            (cur.address == null || cur.address!.isEmpty);
        final hasBetterDec = (t.decimals != null) && (cur.decimals == null);
        if (hasBetterAddr || hasBetterDec) {
          bySymbol[t.symbol] = t;
        }
      }
    }

    _tokensCache[chainId] = bySymbol.values.toList();
  }

  String _normalizeCakeNativeTokenName(String title) {
    final name = title.toUpperCase();
    return switch (name) {
      "ZZEC" => "ZEC",
      _ => name,
    };
  }

  String _getTokenAddress({required CryptoCurrency currency, required SwapsXyzChain chain}) {
    final symbol = _normalizeCakeNativeTokenName(currency.title);
    final list = _tokensCache[chain.chainId];

    if (list != null && list.isNotEmpty) {
      for (final t in list) {
        if (t.symbol == symbol && t.address != null && t.address!.isNotEmpty) {
          return t.address!;
        } else if (t.symbol == symbol && (t.address == null)) {
          // Native token on this chain
          return "0x0000000000000000000000000000000000000000";
        }
      }
    }

    return symbol;
  }

  Map<String, dynamic>? findTokenBySymbol({required String title, required List<dynamic> tokens}) {
    final reqSymbol = title.toUpperCase();
    for (final token in tokens) {
      final map = token as Map<String, dynamic>;
      final symbol = (map["symbol"] as String?)?.toUpperCase();
      if (symbol == reqSymbol) {
        return map;
      }
    }
    return null;
  }

  SwapsXyzChain _findChainByCurrency(CryptoCurrency cur, List<SwapsXyzChain> chains) {
    final network = _normalizeCakeNetwork(cur.tag ?? cur.title);
    return chains.firstWhere((c) => c.name.toUpperCase() == network, orElse: () => throw Exception("Unsupported chain for ${cur.title}"));
  }

  String _normalizeCakeNetwork(String network) => switch (network.toUpperCase()) {
      "ETH" => "ETHEREUM",
      "BSC" => "BNB SMART CHAIN",
      "POL" => "POLYGON",
      "AVAXC" => "AVALANCHE",
      "TRX" => "TRON",
      "SOL" => "SOLANA",
      "CRO" => "CRONOS",
      "ADA" => "CARDANO",
      "KAS" => "KASPA",
      "TON" => "TONCOIN",
      "BCH" => "BITCOIN CASH",
      "ARB" => "ARBITRUM",
      _ => network.toUpperCase(),
    };


  String _decodeMethodSelector(String s) =>
      (s.startsWith("0x") && s.length >= 10) ? s.substring(0, 10) : "";
}

class TokenPathInfo {

  TokenPathInfo({
    required this.symbol,
    required this.address,
    required this.decimals,
    required this.minAmount,
    required this.maxAmount,
  });

  factory TokenPathInfo.fromJson(Map<String, dynamic> json) => TokenPathInfo(
    symbol: (json["symbol"] as String?)?.toUpperCase() ?? "",
    address: json["address"] as String?,
    decimals: json["decimals"] as int?,
    minAmount: json["minAmount"]?.toString(),
    maxAmount: json["maxAmount"]?.toString(),
  );
  final String symbol;
  final String? address;
  final int? decimals;
  final String? minAmount;
  final String? maxAmount;
}

class _PathInfo {

  _PathInfo({required this.supportsExactOut, required this.minToAmountHuman});
  final bool supportsExactOut;
  final String minToAmountHuman;
}
