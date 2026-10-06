import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_api_schema.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:json_annotation/json_annotation.dart";

class SwapsXyzTrade extends RoutableTrade {
  SwapsXyzTrade({
    required this.needToRegister,
    required this.sourceTokenAddress,
    required this.sourceTokenDecimals,
    required this.sourceTokenAmountRaw,
    required this.requiresTokenApproval,
    required super.fundingAddress,
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

class SwapsXyzExchangeProvider extends ExchangeProvider
    implements TransactionCreationExchangeProvider {
  SwapsXyzExchangeProvider({required SettingsStore settingsStore, super.proxyWrapper})
    : _settingsStore = settingsStore;

  final SettingsStore _settingsStore;

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
  bool get supportsFixedRate => false;

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
    final res = await proxyWrapper.get(clearnetUri: uri, headers: _headers);
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

      if (tokensField.isNotEmpty) {
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
            min: Money.trySafeParse(match.minAmount, from),
            max: Money.trySafeParse(match.maxAmount, from),
          );
        }
      }
    }
    return ExchangeLimits(
      min: Money.trySafeParse(path.amountLimits?.minAmount, from),
      max: Money.trySafeParse(path.amountLimits?.maxAmount, from),
    );
  }

  Future<SwapsXyzChainPath?> _pickPath({
    required int srcChainId,
    required String srcToken,
    required int dstChainId,
    required String dstToken,
  }) async {
    final params = SwapsXyzPathsRequest(
      srcChainId: srcChainId.toString(),
      srcToken: srcToken,
      dstChainId: dstChainId.toString(),
      dstToken: dstToken,
    );

    final uri = Uri.https(_baseUrl, _getPaths, params.toJson());
    final res = await proxyWrapper.get(clearnetUri: uri, headers: _headers);
    if (res.statusCode != 200) {
      return null;
    }

    return SwapsXyzPathsResponse.fromJson(
      json.decode(res.body) as Map<String, dynamic>,
    ).paths.firstOrNull;
  }

  @override
  Future<ProviderRate> fetchRate({
    required Money from,
    required CryptoCurrency to,
    required bool isFixedRate,
  }) async {
    if (_notSupportedAsSourceToken.contains(from.currency as CryptoCurrency)) {
      throw Exception(
        "fetchRate: source token ${from.currency.symbol} is not supported as source token",
      );
    }

    if(_notSupportedAsSourceToken.contains(to)) {
      throw Exception(
        "fetchRate: source token ${from.currency.symbol} is not supported as destination token",
      );
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
      if (path == null || !path.supportsExactAmountOut) {
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
      amount: from.amount.toString(),
      swapDirection: .exactAmountIn,
    );

    final uri = Uri.https(_baseUrl, _getQuotePaths, params.toJson());
    final response = await proxyWrapper.get(clearnetUri: uri, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception("fetchRate failed: ${response.body}");
    }

    final data = SwapsXyzQuote.fromJson(json.decode(response.body) as Map<String, dynamic>);
    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(
        Money(data.amountIn.amount, from.currency),
        Money(data.amountOut.amount, to),
      ),
      limits: await fetchLimits(
        from: from.currency as CryptoCurrency,
        to: to,
        isFixedRateMode: isFixedRate,
      ),
    );
  }

  @override
  Future<Trade> createTrade({required TradeRequest request}) async {
    final sender = request.refundAddress.trim();
    final recipient = request.payoutAddress.trim();
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
        ? request.payoutAmount
        : request.depositAmount;

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
    final res = await proxyWrapper.get(clearnetUri: uri, headers: _headers);

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
      depositAmount: request.depositAmount,
      payoutAmount: request.payoutAmount,
      fundingAddress: txTo ?? "",
      createdAt: DateTime.now(),
      id: txId,
      provider: description,
      payoutAddress: request.payoutAddress,
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
  Future<bool> registerAltVmTx({
    required String txId,
    required String txHash,
    required int chainId,
    required String vmId,
  }) async {
    try {
      final uri = Uri.https(_baseUrl, _registerTxs);
      final payload = {"txId": txId, "vmId": vmId, "txHash": txHash, "chainId": chainId};

      final res = await proxyWrapper.post(
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
  Future<Trade> updateTrade(Trade trade) async {
    final uri = Uri.https(_baseUrl, _getStatus, {"txId": trade.id});
    final resp = await proxyWrapper.get(clearnetUri: uri, headers: _headers);

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



    final txHash = srcTransaction?.txHash;

    // Minimal-unit amounts like "12000n"
    final srcAmountRaw = srcPaymentToken?.amount;
    final dstAmountRaw = dstPaymentToken?.amount;


    // Timestamps can be num or "123n"  handle both
    final srcTs = srcTransaction?.timestamp;
    final dstTs = dstTransaction?.timestamp;
    final timestamp = srcTs ?? dstTs;

    return trade.copyWith(
      id: data.txId,
      provider: description,
      fundingAddress: inputAddress ?? "",
      payoutAddress: dstTransaction?.toAddress ?? "",
      txId: txHash,
      state: status,
      createdAt: timestamp,
      refundAddress: refundAddress,
      depositAmount: Money(srcAmountRaw ?? BigInt.zero, trade.depositCurrency),
      payoutAmount: Money(dstAmountRaw ?? BigInt.zero, trade.payoutCurrency),
    );
  }

  // Load & cache supported chains once
  Future<List<SwapsXyzChain>> _getSupportedChains() async {
    if (_supportedChainList.isNotEmpty) {
      return _supportedChainList;
    }
    try {
      final uri = Uri.https(_baseUrl, _getChainList);
      final response = await proxyWrapper.get(clearnetUri: uri, headers: _headers);
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
    final params = SwapsXyzPathsRequest(
      srcChainId: srcChainId.toString(),
      // Native placeholder
      srcToken: "0x0000000000000000000000000000000000000000",
    );

    final uri = Uri.https(_baseUrl, _getPaths, params.toJson());
    final res = await proxyWrapper.get(clearnetUri: uri, headers: _headers);
    if (res.statusCode != 200) {
      printV("getPaths failed: ${res.statusCode} ${res.body}");
      return;
    }

    final SwapsXyzPathsResponse body;
    try {
      body = SwapsXyzPathsResponse.fromJson(json.decode(res.body) as Map<String, dynamic>);
    } catch (e) {
      printV("getPaths parse error: $e");
      return;
    }

    // Always cache the source chain's native token
    if (body.srcToken.symbol.isNotEmpty) {
      // Treat native token as address = null so _getTokenAddress() emits zero-address
      _mergeCache(srcChainId, [TokenPathInfo.fromToken(body.srcToken, dropNativeAddress: true)]);
    }

    for (final path in body.paths) {
      // "all" -> cache empty list to indicate all tokens supported
      if (path.tokens.isAll) {
        _tokensCache[path.chainId] ??= <TokenPathInfo>[];
      } else if (path.tokens.isNotEmpty) {
        _mergeCache(path.chainId, path.tokens.tokens!.map(TokenPathInfo.fromToken).toList());
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
    return chains.firstWhere(
      (c) => c.name.toUpperCase() == network,
      orElse: () => throw Exception("Unsupported chain for ${cur.title}"),
    );
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

  @override
  Future<PendingTransaction> createTransaction(WalletBase wallet, Trade trade) async {
    trade as SwapsXyzTrade;

    final routerTo = trade.fundingAddress;
    final routerData = trade.routerData;

    if (routerData == "0x") {
      throw Exception("invalid router data");
    }

    final tokenContract = trade.sourceTokenAddress.toLowerCase();
    final priority = _settingsStore.getPriority(wallet.type, chainId: wallet.chainId);
    final routerValueWei = BigInt.tryParse(trade.routerValue) ?? BigInt.zero;

    final selector = _decodeMethodSelector(routerData);
    const transferSig = "0xa9059cbb";
    const swapAndExecuteSig = "0x9be111d1";

    // Direct Transfer (Simple routing, no approval needed)
    if (selector == transferSig) {
      return evm!.createRawCallDataTransaction(
        wallet,
        routerTo,
        routerData,
        Money.zero(wallet.currency),
        priority,
        useBlinkProtection: canSupportBlinkProtection(wallet.chainId)
            ? _settingsStore.useBlinkProtection
            : false,
      );
    }

    // Smart Swap (Requires Approval)
    if (selector == swapAndExecuteSig) {
      final requiredAmount =
          BigInt.tryParse(trade.sourceTokenAmountRaw.replaceAll("n", "")) ?? BigInt.zero;

      final needsApproval = tokenContract.isNotEmpty && requiredAmount > BigInt.zero
          ? await evm!.isApprovalRequired(wallet, tokenContract, routerTo, requiredAmount)
          : false;

      printV(
        "[Swaps.xyz sending flow] Approval required: $needsApproval for token ${trade.depositAmount.serialized} with amount $requiredAmount",
      );

      if (needsApproval) {
        // USDT Approval Flow (Special Case). We must reset allowance to 0 first.
        final isUSDTMainnet =
            wallet.chainId == 1 &&
            tokenContract.toLowerCase() == "0xdac17f958d2ee523a2206206994597c13d831ec7";

        if (isUSDTMainnet) {
          final currentAllowance = await evm!.getAllowance(wallet, tokenContract, routerTo);

          if (currentAllowance != null && currentAllowance > BigInt.zero) {
            printV(
              "[Swaps.xyz sending flow] currentAllowance USDT: $currentAllowance. Resetting to 0 before setting new allowance.",
            );

            final resetTx = await buildApprovalNeeded(
              wallet: wallet,
              spender: routerTo,
              tokenContract: tokenContract,
              requiredAmount: BigInt.zero,
              // Approve 0
              sourceTokenDecimals: trade.sourceTokenDecimals,
              priority: priority,
            );

            if (resetTx != null) {
              await resetTx.commit();

              final resetConfirmed = await _waitForApprovalUpdate(
                wallet: wallet,
                tokenContract: tokenContract,
                spender: routerTo,
                requiredAmount: BigInt.zero,
                // Wait until it equals 0
                waitForExactMatch: true,
              );

              if (!resetConfirmed) {
                throw Exception("Failed to reset USDT allowance. Please try again.");
              }
              printV("[Swaps.xyz sending flow] USDT allowance reset to 0 confirmed on-chain.");
            }
          }
        }

        // Standard Approval Flow
        final approvalTx = await buildApprovalNeeded(
          wallet: wallet,
          spender: routerTo,
          tokenContract: tokenContract,
          requiredAmount: requiredAmount,
          sourceTokenDecimals: trade.sourceTokenDecimals,
          priority: priority,
        );

        if (approvalTx == null) {
          throw Exception("Failed to build approval transaction");
        }

        printV(
          "[Swaps.xyz sending flow] Submitting approval transaction for token ${trade.depositAmount.serialized}",
        );
        await approvalTx.commit();

        // Wait for the approval to be mined on-chain
        final isApproved = await _waitForApprovalUpdate(
          wallet: wallet,
          tokenContract: tokenContract,
          spender: routerTo,
          requiredAmount: requiredAmount,
        );

        if (!isApproved) {
          throw Exception("Approval transaction failed or timed out on-chain. Try again.");
        }
        printV(
          "[Swaps.xyz sending flow] Approval transaction confirmed on-chain. Proceeding with swap execution.",
        );
      }

      // Construct Final Swap Transaction
      printV("[Swaps.xyz sending flow] Building swap transaction");
      return evm!.createRawCallDataTransaction(
        wallet,
        routerTo,
        routerData,
        Money(routerValueWei, wallet.currency),
        priority,
        sourceTokenAddress: tokenContract,
        sourceTokenAmount: requiredAmount,
        useBlinkProtection: canSupportBlinkProtection(wallet.chainId)
            ? _settingsStore.useBlinkProtection
            : false,
      );
    }

    throw Exception("invalid selector");
  }

  Future<PendingTransaction?> buildApprovalNeeded({
    required WalletBase wallet,
    required String spender,
    required String tokenContract,
    required BigInt requiredAmount,
    required TransactionPriority? priority,
    int? sourceTokenDecimals,
  }) {
    final erc20Token = wallet.balance.keys.whereType<Erc20Token>().firstWhere(
      (t) => t.contractAddress.toLowerCase() == tokenContract.toLowerCase(),
      orElse: () => Erc20Token(
        name: "",
        symbol: "",
        contractAddress: tokenContract,
        decimal: sourceTokenDecimals ?? 18,
        enabled: true,
      ),
    );

    return evm!.createTokenApproval(
      wallet,
      Money(requiredAmount, erc20Token),
      spender,
      priority,
      useBlinkProtection: canSupportBlinkProtection(wallet.chainId)
          ? _settingsStore.useBlinkProtection
          : false,
    );
  }

  Future<bool> _waitForApprovalUpdate({
    required WalletBase wallet,
    required String tokenContract,
    required String spender,
    required BigInt requiredAmount,
    bool waitForExactMatch = false,
  }) async {
    int attempts = 0;
    const int maxAttempts = 30; // ~60 seconds

    printV(
      "[Swaps.xyz sending flow] Starting allowance check. Target: $requiredAmount (Exact match: $waitForExactMatch)",
    );

    while (attempts < maxAttempts) {
      try {
        final currentAllowance = await evm!.getAllowance(wallet, tokenContract, spender);

        if (currentAllowance != null) {
          printV(
            "[Swaps.xyz sending flow] Current Allowance: $currentAllowance / Target: $requiredAmount",
          );

          if (waitForExactMatch) {
            // For Reset (Target 0): We need it to be exactly 0 (or less, though it can't be negative)
            if (currentAllowance <= requiredAmount) {
              printV("[Swaps.xyz sending flow] Allowance reset verified!");
              return true;
            }
          } else {
            // For Approval: We need it to be at least the required amount
            if (currentAllowance >= requiredAmount) {
              printV("[Swaps.xyz sending flow] Allowance verified!");
              return true;
            }
          }
        }
      } catch (e) {
        printV("[Swaps.xyz sending flow] Allowance check error: $e");
      }

      await Future.delayed(const Duration(seconds: 1));
      attempts++;
    }

    printV("[Swaps.xyz sending flow] Allowance check timed out.");
    return false;
  }

  Future<void> registerSwapsXyzTransaction(Trade trade, PendingTransaction pendingTransaction) async {
    trade as SwapsXyzTrade;
      // register only for vmId is alt-vm or bridgeId is alt-vm (trade.needToRegisterInSwapXyz)
      final needToRegister = trade.needToRegister;
      if (!needToRegister) {
        return;
      }

      final vmId = (trade.providerId ?? "").toLowerCase();
      if (vmId.isEmpty) {
        printV("SwapsXyz: transaction register: skipped (vmId empty)");
        return;
      }

      final txHash = pendingTransaction.evmTxHashFromRawHex ?? pendingTransaction.id;

      if (txHash.isEmpty) {
        printV("SwapsXyz: transaction register: skipped (txHash empty)");
        return;
      }

      final chainId = int.tryParse(trade.router ?? "") ?? 0;
      if (chainId <= 0) {
        printV("SwapsXyz: transaction register: skipped (invalid chainId)");
        return;
      }

      printV(
          "SwapsXyz: attempting to register transaction: tradeId = ${trade.id}, txHash = $txHash, chainId = $chainId, vmId = $vmId");

      final registered = await registerAltVmTx(
        txId: trade.id,
        txHash: txHash,
        chainId: chainId,
        vmId: vmId,
      );

      if (!registered) {
        printV("SwapsXyz: transaction register: failed");
      } else {
        printV("SwapsXyz: transaction register: success");
      }
  }
}

class TokenPathInfo {
  TokenPathInfo({
    required this.symbol,
    required this.address,
    required this.decimals,
    required this.minAmount,
    required this.maxAmount,
  });

  factory TokenPathInfo.fromToken(
    SwapsXyzTokenInfoWithAmounts token, {
    bool dropNativeAddress = false,
  }) => TokenPathInfo(
    symbol: token.symbol.toUpperCase(),
    address: dropNativeAddress && token.isNative ? null : token.address,
    decimals: token.decimals,
    minAmount: token.minAmount,
    maxAmount: token.maxAmount,
  );
  final String symbol;
  final String? address;
  final int? decimals;
  final String? minAmount;
  final String? maxAmount;
}
