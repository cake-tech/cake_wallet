import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/provider/swapsxyz/swapsxyz_api_schema.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/provider_api.dart";
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

class SwapsXyzTrade extends RoutableTrade {
  SwapsXyzTrade({
    required this.vmId, required this.needToRegister,
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

  final bool needToRegister;
  final String sourceTokenAddress;
  final int sourceTokenDecimals;
  final SwapsXyzVmId vmId;
  final String sourceTokenAmountRaw;
  final bool requiresTokenApproval;
}

class SwapsXyzExchangeProvider extends ExchangeProvider
    implements TransactionCreationExchangeProvider, TransactionRegistrationExchangeProvider {
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

  late final _api = ProviderApi(
    proxyWrapper,
    authority: _baseUrl,
    headers: {"x-api-key": _apiKey},
    errorMessage: SwapsXyzErrorResponse.messageOf,
  );

  static final _supportedChainList = <SwapsXyzChain>[];
  final Map<int, List<TokenPathInfo>> _tokensCache = {};

  @override
  bool get supportsFixedRate => false;

  @override
  ExchangeProviderDescription get description => ExchangeProviderDescription.swapsXyz;

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

    final body = await _api.send(
      SwapsXyzPathsRequest(
        srcChainId: srcChain.chainId.toString(),
        srcToken: srcToken,
        dstChainId: dstChain.chainId.toString(),
        dstToken: dstToken,
      ),
    );

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
    try {
      final response = await _api.send(
        SwapsXyzPathsRequest(
          srcChainId: srcChainId.toString(),
          srcToken: srcToken,
          dstChainId: dstChainId.toString(),
          dstToken: dstToken,
        ),
      );
      return response.paths.firstOrNull;
    } on ProviderHttpException {
      return null;
    }
  }

  @override
  Future<ProviderRate> fetchRate(RateRequest request) async {
    if (_notSupportedAsSourceToken.contains(request.depositCurrency)) {
      throw Exception(
        "fetchRate: source token ${request.depositCurrency.symbol} is not supported as source token",
      );
    }

    if(_notSupportedAsSourceToken.contains(request.payoutCurrency)) {
      throw Exception(
        "fetchRate: source token ${request.payoutCurrency.symbol} is not supported as destination token",
      );
    }

    final chains = await _getSupportedChains();
    if (chains.isEmpty) {
      throw Exception("chains.isEmpty");
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

    if (request is FixedRateRequest) {
      final path = await _pickPath(
        srcChainId: srcChain.chainId,
        srcToken: srcToken,
        dstChainId: dstChain.chainId,
        dstToken: dstToken,
      );
      if (path == null || !path.supportsExactAmountOut) {
        throw Exception(
          "fetchRate: route does not support exact-amount-out for ${request.depositCurrency.symbol} -> ${request.payoutCurrency.title}",
        );
      }
    }

    final data = await _api.send(
      SwapsXyzQuoteRequest(
        srcChainId: srcChain.chainId.toString(),
        srcToken: srcToken,
        dstChainId: dstChain.chainId.toString(),
        dstToken: dstToken,
        amount: request.amount.amount.toString(),
        swapDirection: switch (request) {
          FloatingRateRequest() => .exactAmountIn,
          FixedRateRequest() => .exactAmountOut,
        },
      ),
    );
    return ProviderRate(
      provider: description,
      rate: ExchangeRate.fromAmounts(
        Money(data.amountIn.amount, request.depositCurrency),
        Money(data.amountOut.amount, request.payoutCurrency),
      ),
      limits: await fetchLimits(
        from: request.depositCurrency,
        to: request.payoutCurrency,
        isFixedRateMode: request is FixedRateRequest,
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

    final data = await _api.send(
      SwapsXyzActionRequest(
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
      ),
    );

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
      vmId: vmId,
      needToRegister: needToRegisterInSwapXyz,
      sourceTokenAddress: data.amountIn.address,
      sourceTokenDecimals: data.amountIn.decimals,
      sourceTokenAmountRaw: data.amountInMax.amount.toString(),
      requiresTokenApproval: data.requiresTokenApproval,
    );
  }

  /// Alt-vm routes are only picked up once their source tx is registered with Swaps.xyz.
  @override
  Future<Trade> registerTransaction(Trade trade, String txHash) async {
    trade as SwapsXyzTrade;

    if (!trade.needToRegister) {
      return trade;
    }

    final chainId = int.tryParse(trade.router ?? "");
    if (chainId == null || chainId <= 0) {
      throw Exception("Can't register $txHash, invalid chain id ${trade.router}");
    }

    final response = await _api.send(
      SwapsXyzTxRegistrationRequest(
        txId: trade.id,
        txHash: txHash,
        vmId: trade.vmId.toJson(),
        chainId: chainId,
      ),
    );

    if (response.firstOrNull?.success != true) {
      throw Exception("Swaps.xyz didn't accept the registration of $txHash");
    }

    return trade;
  }

  @override
  Future<Trade> updateTrade(Trade trade) async {
    final data = await _api.send(SwapsXyzStatusRequest(txId: trade.id));

    return trade.copyWith(
      id: data.txId,
      provider: description,
      fundingAddress: data.srcTx?.toAddress,
      payoutAddress: data.dstTx?.toAddress,
      txId: data.srcTx?.txHash,
      state: data.status.toState,
      createdAt: data.srcTx?.timestamp ?? data.dstTx?.timestamp,
      refundAddress: data.sender,
      depositAmount: _moneyOf(data.srcTx?.paymentToken, trade.depositCurrency),
      payoutAmount: _moneyOf(data.dstTx?.paymentToken, trade.payoutCurrency),
    );
  }

  Money? _moneyOf(SwapsXyzToken? token, CryptoCurrency currency) => token == null
      ? null
      : Money(token.amount, currency, token.decimals).copyWith(currency: currency);

  // Load & cache supported chains once
  Future<List<SwapsXyzChain>> _getSupportedChains() async {
    if (_supportedChainList.isNotEmpty) {
      return _supportedChainList;
    }
    try {
      final data = await _api.send(const SwapsXyzChainListRequest());
      _supportedChainList
        ..clear()
        ..addAll(data);
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
    final SwapsXyzPathsResponse body;
    try {
      body = await _api.send(
        SwapsXyzPathsRequest(
          srcChainId: srcChainId.toString(),
          // Native placeholder
          srcToken: "0x0000000000000000000000000000000000000000",
        ),
      );
    } catch (e) {
      printV("getPaths failed: $e");
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
  Future<PendingTransaction?> createTransaction(WalletBase wallet, Trade trade) async {
    trade as SwapsXyzTrade;

    final routerTo = trade.fundingAddress;
    final routerData = trade.routerData;

    if (!isEVMCompatibleChain(wallet.type) || routerData.isEmpty || routerData == "0x") {
      return null;
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

      Future<PendingTransaction> buildSwap() {
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

      final needsApproval = tokenContract.isNotEmpty && requiredAmount > BigInt.zero
          ? await evm!.isApprovalRequired(wallet, tokenContract, routerTo, requiredAmount)
          : false;

      printV(
        "[Swaps.xyz sending flow] Approval required: $needsApproval for token ${trade.depositAmount.serialized} with amount $requiredAmount",
      );

      if (!needsApproval) {
        return buildSwap();
      }

      // USDT Approval Flow (Special Case). We must reset allowance to 0 first.
      final isUSDTMainnet =
          wallet.chainId == 1 &&
          tokenContract.toLowerCase() == "0xdac17f958d2ee523a2206206994597c13d831ec7";
      final currentAllowance =
          isUSDTMainnet ? await evm!.getAllowance(wallet, tokenContract, routerTo) : null;
      final needsReset = currentAllowance != null && currentAllowance > BigInt.zero;

      if (needsReset) {
        printV(
          "[Swaps.xyz sending flow] currentAllowance USDT: $currentAllowance. Resetting to 0 before setting new allowance.",
        );
      }

      Future<PendingTransaction> buildApproval(BigInt amount) async {
        final approvalTx = await buildApprovalNeeded(
          wallet: wallet,
          spender: routerTo,
          tokenContract: tokenContract,
          requiredAmount: amount,
          sourceTokenDecimals: trade.sourceTokenDecimals,
          priority: priority,
        );

        if (approvalTx == null) {
          throw Exception("Failed to build approval transaction");
        }
        return approvalTx;
      }

      Future<void> sendApproval(PendingTransaction approvalTx, BigInt amount) async {
        printV(
          "[Swaps.xyz sending flow] Submitting approval transaction for token ${trade.depositAmount.serialized} with amount $amount",
        );
        await approvalTx.commit();

        final isReset = amount == BigInt.zero;
        final isApproved = await _waitForApprovalUpdate(
          wallet: wallet,
          tokenContract: tokenContract,
          spender: routerTo,
          requiredAmount: amount,
          waitForExactMatch: isReset,
        );

        if (!isApproved) {
          throw Exception(
            isReset
                ? "Failed to reset USDT allowance. Please try again."
                : "Approval transaction failed or timed out on-chain. Try again.",
          );
        }
        printV("[Swaps.xyz sending flow] Approval to $amount confirmed on-chain.");
      }

      final firstApproval = await buildApproval(needsReset ? BigInt.zero : requiredAmount);

      return _ApproveThenSwapTransaction(firstApproval, () async {
        await sendApproval(firstApproval, needsReset ? BigInt.zero : requiredAmount);
        if (needsReset) {
          await sendApproval(await buildApproval(requiredAmount), requiredAmount);
        }

        final swapTx = await buildSwap();
        await swapTx.commit();
        return swapTx;
      });
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
}

class _ApproveThenSwapTransaction with PendingTransaction {
  _ApproveThenSwapTransaction(this._firstApproval, this._send);

  final PendingTransaction _firstApproval;
  final Future<PendingTransaction> Function() _send;
  PendingTransaction? _swap;

  PendingTransaction get _current => _swap ?? _firstApproval;

  @override
  String get id => _current.id;

  @override
  Money get amount => _current.amount;

  @override
  Money get fee => _current.fee;

  @override
  String get amountFormatted => _current.amountFormatted;

  @override
  String get feeFormatted => _current.feeFormatted;

  @override
  String get feeFormattedValue => _current.feeFormattedValue;

  @override
  String get hex => _current.hex;

  @override
  String? get evmTxHashFromRawHex => _current.evmTxHashFromRawHex;

  @override
  Future<void> commit() async => _swap = await _send();

  @override
  Future<Map<String, String>> commitUR() => throw UnimplementedError();
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
