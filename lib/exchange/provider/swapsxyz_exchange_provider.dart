import 'dart:convert';
import 'dart:math';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/limits.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_not_created_exception.dart';
import 'package:cake_wallet/exchange/trade_request.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/exchange/utils/currency_pairs_utils.dart';
import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/crypto_currency.dart';

class SwapsXyzExchangeProvider extends ExchangeProvider {
  SwapsXyzExchangeProvider() : super(pairList: supportedPairs(_notSupported));

  static const List<CryptoCurrency> _notSupported = [];

  static final _apiKey = secrets.swapsXyzApiKey;
  static const _baseUrl = 'api-v2.swaps.xyz';
  static const _getChainList = 'api/getChainList';
  static const _getPaths = 'api/getPaths';
  static const _getQuotePaths = 'api/getQuote';
  static const _getAction = 'api/getAction';
  static const _registerTxs = 'api/registerTxs';
  static const _getStatus = 'api/getStatus';

  static final _headers = {'x-api-key': _apiKey};

  static final _supportedChainList = <Chain>[];
  final Map<int, List<TokenPathInfo>> _tokensCache = {};

  @override
  String get title => 'Swaps.XYZ';

  @override
  bool get isAvailable => true;

  @override
  bool get isEnabled => true;

  @override
  bool get supportsFixedRate => true;

  @override
  ExchangeProviderDescription get description =>
      ExchangeProviderDescription.swapsXyz;

  @override
  Future<bool> checkIsAvailable() async => true;

  @override
  Future<Limits> fetchLimits({
    required CryptoCurrency from,
    required CryptoCurrency to,
    required bool isFixedRateMode,
  }) async {
    try {
      final chains = await _geSupportedChain();
      if (chains.isEmpty) throw Exception('Failed to fetch supported chains');

      final srcChain = _findChainByCurrency(from, chains);
      final dstChain = _findChainByCurrency(to, chains);

      await _ensureTokensCached(
          fromChain: srcChain, toChain: dstChain, from: from, to: to);

      final srcToken = _getTokenAddress(currency: from, chain: srcChain);
      final dstToken = _getTokenAddress(currency: to, chain: dstChain);

      final params = {
        'srcChainId':  '${srcChain.chainId}',
        'srcToken': srcToken,
        'dstChainId':'${dstChain.chainId}',
        'dstToken': dstToken,
      };

      final uri = Uri.https(_baseUrl, _getPaths, params);
      final res = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
      if (res.statusCode != 200) {
        throw Exception('Unexpected http status: ${res.statusCode}');
      }

      final body = json.decode(res.body) as Map<String, dynamic>;

      final paths = (body['paths'] as List?) ?? const [];
      if (paths.isEmpty) {
        throw Exception('No paths for ${from.title} -> ${to.title}');
      }

      final path0 = paths.first as Map<String, dynamic>;
      final amountLimits = path0['amountLimits'] as Map<String, dynamic>?;

      double? _parsedToDouble(dynamic v) =>
          (v == null || v.toString().isEmpty) ? null : double.tryParse(v.toString());

      final min = _parsedToDouble(amountLimits?['minAmount']);
      final max = _parsedToDouble(amountLimits?['maxAmount']);

      return Limits(min: min, max: max);
    } catch (e) {
      printV('fetchLimits error: $e');
      throw Exception('Error fetching limits: $e');
    }
  }

  Future<_PathInfo?> _pickPath({
    required int srcChainId,
    required String srcToken,
    required int dstChainId,
    required String dstToken,
  }) async {
    final uri = Uri.https(_baseUrl, _getPaths, {
      'srcChainId': '$srcChainId',
      'srcToken': srcToken,
      'dstChainId': '$dstChainId',
      'dstToken': dstToken,
    });
    final res = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
    if (res.statusCode != 200) return null;
    final body = json.decode(res.body) as Map<String, dynamic>;
    final paths =
        (body['paths'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (paths.isEmpty) return null;
    final p = paths.first;
    return _PathInfo(
      supportsExactOut: p['supportsExactAmountOut'] == true,
      minToAmountHuman: (p['amountLimits']?['minAmount'] as String?) ?? '0',
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
      final chains = await _geSupportedChain();
      if (chains.isEmpty) return 0.0;

      final srcChain = _findChainByCurrency(from, chains);
      final dstChain = _findChainByCurrency(to, chains);

      await _ensureTokensCached(
          fromChain: srcChain, toChain: dstChain, from: from, to: to);

      final srcToken = _getTokenAddress(currency: from, chain: srcChain);
      final dstToken = _getTokenAddress(currency: to, chain: dstChain);

      if (isReceiveAmount) {
        final path = await _pickPath(
          srcChainId: srcChain.chainId,
          srcToken: srcToken,
          dstChainId: dstChain.chainId,
          dstToken: dstToken,
        );
        if (path == null || !path.supportsExactOut) {
          printV(
              'fetchRate: route does not support exact-amount-out for ${from.title} -> ${to.title}');
          return 0.0;
        }
      }

      final humanAmountStr = amount.toString();
      final formattedAmount = AmountConverter.toBaseUnits(
        humanAmountStr,
        isReceiveAmount ? to.decimals : from.decimals,
      );

      final params = {
        'swapDirection':
            isReceiveAmount ? 'exact-amount-out' : 'exact-amount-in',
        'srcToken': srcToken,
        'dstToken': dstToken,
        'srcChainId': '${srcChain.chainId}',
        'dstChainId': '${dstChain.chainId}',
        'amount': formattedAmount,
      };

      final uri = Uri.https(_baseUrl, _getQuotePaths, params);
      final response =
          await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

      if (response.statusCode != 200) {
        printV('fetchRate failed: ${response.body}');
        return 0.0;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final exchangeRate = (data['exchangeRate'] as num?)?.toDouble() ?? 0.0;
      return exchangeRate;
    } catch (e) {
      printV('fetchRate error: $e');
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
      final sender = request.refundAddress.trim();
      final recipient = request.toAddress.trim();
      if (sender.isEmpty || recipient.isEmpty) {
        throw Exception(
            'Sender (refundAddress) or recipient (toAddress) is empty');
      }

      final chains = await _geSupportedChain();
      if (chains.isEmpty) throw Exception('Failed to fetch supported chains');
      final srcChain = _findChainByCurrency(request.fromCurrency, chains);
      final dstChain = _findChainByCurrency(request.toCurrency, chains);

      await _ensureTokensCached(
        fromChain: srcChain,
        toChain: dstChain,
        from: request.fromCurrency,
        to: request.toCurrency,
      );

      final srcToken =
          _getTokenAddress(currency: request.fromCurrency, chain: srcChain);
      final dstToken =
          _getTokenAddress(currency: request.toCurrency, chain: dstChain);

      // Optional: ensure path supports exact-out before attempting fixed rate.
      if (isFixedRateMode) {
        final path = await _pickPath(
          srcChainId: srcChain.chainId,
          srcToken: srcToken,
          dstChainId: dstChain.chainId,
          dstToken: dstToken,
        );
        if (path == null || !path.supportsExactOut) {
          throw Exception(
              'This route does not support fixed receive (exact-amount-out)');
        }
      }

      final amountStr = isFixedRateMode ? request.toAmount : request.fromAmount;
      final rawAmount = double.tryParse(amountStr) ?? 0.0;
      if (rawAmount <= 0) throw Exception('Invalid amount');

      final formattedAmount = AmountConverter.toBaseUnits(
        amountStr,
        isFixedRateMode
            ? request.toCurrency.decimals
            : request.fromCurrency.decimals,
      );

      final params = {
        'actionType': 'swap-action',
        'sender': sender,
        'srcChainId': '${srcChain.chainId}',
        'srcToken': srcToken,
        'dstChainId': '${dstChain.chainId}',
        'dstToken': dstToken,
        'slippage': '300',
        'swapDirection':
            isFixedRateMode ? 'exact-amount-out' : 'exact-amount-in',
        'amount': formattedAmount,
        'recipient': recipient,
      };

      final uri = Uri.https(_baseUrl, _getAction, params);
      final res = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

      if (res.statusCode != 200) {
        throw Exception('getAction failed: ${res.statusCode} ${res.body}');
      }

      final data = json.decode(res.body) as Map<String, dynamic>;

      final txId = data['txId'] as String? ?? '';
      final vmId = data['vmId'] as String? ?? '';
      final txObj = (data['tx'] as Map?) ?? const {};

      final txTo = txObj['to']?.toString();
      final chainId = txObj['chainId']?.toString();
      final routerData = txObj['data']?.toString();
      final txValue = txObj['value']?.toString() ?? '0';

      final bridgeIds = (data['bridgeIds'] as List?) ?? const [];
      if (txId.isEmpty) throw Exception('No txId returned by getAction');

      final amtIn = (data['amountIn'] as Map?) ?? const {};
      final amtInMax = (data['amountInMax'] as Map?) ?? const {};
      final srcTokenAddr = amtIn['address']?.toString();
      final srcTokenDecs =
          (amtIn['decimals'] as num?)?.toInt() ?? request.fromCurrency.decimals;
      final requiresTokenApproval =
          data['requiresTokenApproval'] as bool? ?? false;

      final reqAmountStr =
          (amtInMax['amount'] ?? amtIn['amount'])?.toString() ?? '0';
      final reqAmountRaw = reqAmountStr.replaceAll('n', '');

      final needToRegisterInSwapXyz =
          vmId == 'alt-vm' || bridgeIds.contains('alt-vm');

      final trade = Trade(
        id: txId,
        router: chainId,
        providerId: vmId,
        from: request.fromCurrency,
        to: request.toCurrency,
        provider: description,
        inputAddress: txTo,
        refundAddress: request.refundAddress,
        state: TradeState.created,
        providerName: title,
        createdAt: DateTime.now(),
        amount: request.fromAmount,
        receiveAmount: request.toAmount,
        payoutAddress: request.toAddress,
        isSendAll: isSendAll,
        needToRegisterInSwapXyz: needToRegisterInSwapXyz,
        sourceTokenAddress: srcTokenAddr ?? srcToken,
        sourceTokenDecimals: srcTokenDecs,
        sourceTokenAmountRaw: reqAmountRaw,
        requiresTokenApproval: requiresTokenApproval,
        routerData: routerData,
        routerValue: txValue,
        userCurrencyFromRaw:
            '${request.fromCurrency.title}_${request.fromCurrency.tag ?? ''}',
        userCurrencyToRaw:
            '${request.toCurrency.title}_${request.toCurrency.tag ?? ''}',
      );

      return trade;
    } catch (e) {
      printV('createTrade error: $e');
      throw TradeNotCreatedException(description, description: e.toString());
    }
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
      final payload = {
        'txId': txId,
        'vmId': vmId,
        'txHash': txHash,
        'chainId': chainId,
      };

      final res = await ProxyWrapper().post(
        clearnetUri: uri,
        headers: {
          ..._headers,
          'content-type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode != 200) {
        printV('registerTxs failed: ${res.statusCode} ${res.body}');
        return false;
      }
      final List<dynamic> body = json.decode(res.body) as List<dynamic>;
      if (body.isEmpty) return false;

      final isSuccess =
          (body[0] as Map<String, dynamic>)['success'] as bool? ?? false;

      return isSuccess;
    } catch (e) {
      printV('registerAltVmTx error: $e');
      return false;
    }
  }

  @override
  Future<Trade> findTradeById({required String id}) async {
    if (id.isEmpty) {
      throw Exception('Trade id is empty');
    }

    final uri = Uri.https(_baseUrl, _getStatus, {'txId': id});
    final resp = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);

    if (resp.statusCode != 200) {
      throw Exception('getStatus failed: ${resp.statusCode} ${resp.body}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    final isSuccess = (data['success'] as bool?);

    if (isSuccess != null && !isSuccess) {
      final error = data['error'] as Map<String, dynamic>?;
      if (error != null) {
        final code = error['code']?.toString() ?? 'unknown';
        throw Exception(
            'SwapXyzExchangeProvider findTradeById error: ($id) $code');
      }
    }

    final statusStr = (data['status'] as String?)?.toLowerCase() ?? 'NOT_FOUND';
    final state = _mapSwapsStatusToTradeState(statusStr);

    final refundAddress = data['sender']?.toString();

    final srcTransaction = (data['srcTx'] as Map?)?.cast<String, dynamic>();
    final dstTransaction = (data['dstTx'] as Map?)?.cast<String, dynamic>();

    final inputAddress = srcTransaction?['toAddress']?.toString();

    final payoutAddress = dstTransaction?['toAddress']?.toString();

    final srcPaymentToken =
        (srcTransaction?['paymentToken'] as Map?)?.cast<String, dynamic>();
    final dstPaymentToken =
        (dstTransaction?['paymentToken'] as Map?)?.cast<String, dynamic>();

    final fromSymbol = (srcPaymentToken?['symbol'] as String?) ?? '';
    final toSymbol = (dstPaymentToken?['symbol'] as String?) ?? '';

    CryptoCurrency? toCurrency;
    if (toSymbol.isNotEmpty) {
      toCurrency = CryptoCurrency.safeParseCurrencyFromString(toSymbol);
    }

    final srcDecimals = (srcPaymentToken?['decimals'] as num?)?.toInt() ?? 0;
    final dstDecimals = (dstPaymentToken?['decimals'] as num?)?.toInt() ?? 0;

    final txHash = srcTransaction?['txHash'] as String?;

    // Minimal-unit amounts like "12000n"
    final srcAmountRaw = srcPaymentToken?['amount']?.toString();
    final dstAmountRaw = dstPaymentToken?['amount']?.toString();
    String? receiveAmount;
    if (dstAmountRaw != null) {
      final dstAmountMinimal = _stripN(dstAmountRaw);
      receiveAmount =
          AmountConverter.fromBaseUnits(dstAmountMinimal, dstDecimals);
    }

    final srcAmountMinimal = _stripN(srcAmountRaw);
    final amount = AmountConverter.fromBaseUnits(srcAmountMinimal, srcDecimals);
    final fromCurrency = CryptoCurrency.safeParseCurrencyFromString(fromSymbol);

    // Timestamps can be num or "123n"  handle both
    final srcTs = _parseUnixSeconds(srcTransaction?['timestamp']);
    final dstTs = _parseUnixSeconds(dstTransaction?['timestamp']);
    final timestamp = srcTs ?? dstTs;

    final createdAt = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true)
            .toLocal()
        : null;

    return Trade(
      id: (data['txId'] as String?) ?? id,
      from: fromCurrency,
      to: toCurrency,
      provider: description,
      inputAddress: inputAddress,
      payoutAddress: payoutAddress,
      amount: amount,
      receiveAmount: receiveAmount,
      txId: txHash,
      state: state,
      createdAt: createdAt,
      refundAddress: refundAddress,
      userCurrencyFromRaw: '${fromSymbol.toUpperCase()}' + '_',
      userCurrencyToRaw: '${toSymbol.toUpperCase()}' + '_',
    );
  }

  TradeState _mapSwapsStatusToTradeState(String s) {
    switch (s) {
      case 'pending':
      case 'processing':
        return TradeState.pending;
      case 'success':
      case 'completed':
      case 'complete':
        return TradeState.finished;
      case 'failed':
      case 'cancelled':
      case 'canceled':
      case 'error':
        return TradeState.failed;
      default:
        return TradeState.pending;
    }
  }

  // Load & cache supported chains once
  Future<List<Chain>> _geSupportedChain() async {
    if (_supportedChainList.isNotEmpty) return _supportedChainList;
    try {
      final uri = Uri.https(_baseUrl, _getChainList);
      final response =
          await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as List<dynamic>;
      _supportedChainList
        ..clear()
        ..addAll(data.map((e) => Chain.fromJson(e as Map<String, dynamic>)));
      return _supportedChainList;
    } catch (e) {
      printV(e);
      return [];
    }
  }

  Future<void> _ensureTokensCached({
    required Chain fromChain,
    required Chain toChain,
    required CryptoCurrency from,
    required CryptoCurrency to,
  }) async {
    final needSrc = !_tokensCache.containsKey(fromChain.chainId) ||
        (_tokensCache[fromChain.chainId]?.isEmpty ?? true);

    final needDst = !_tokensCache.containsKey(toChain.chainId) ||
        (_tokensCache[toChain.chainId]?.isEmpty ?? true);

    if (!needSrc && !needDst) return;

    if (needSrc) {
      await _fetchAndCacheTokens(srcChainId: fromChain.chainId);
    }
    if (needDst) {
      await _fetchAndCacheTokens(srcChainId: toChain.chainId);
    }
  }

  // call getPaths and merge tokens into cache keyed by the chainId
  Future<void> _fetchAndCacheTokens({
    required int srcChainId,
  }) async {
    final params = <String, String>{
      'srcChainId': '$srcChainId',
      'srcToken': '0x0000000000000000000000000000000000000000',
      // Native placeholder
    };

    final uri = Uri.https(_baseUrl, _getPaths, params);
    final res = await ProxyWrapper().get(clearnetUri: uri, headers: _headers);
    if (res.statusCode != 200) {
      printV('getPaths failed: ${res.statusCode} ${res.body}');
      return;
    }

    Map<String, dynamic> body;
    try {
      body = json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      printV('getPaths JSON decode error: $e');
      return;
    }

    final paths = (body['paths'] as List?) ?? const [];
    if (paths.isEmpty) return;

    for (final path in paths) {
      final map = path as Map<String, dynamic>;
      final pathChainId = (map['chainId'] as num?)?.toInt();
      if (pathChainId == null) continue;

      final tokensField = map['tokens'];

      // Case 1: String "all" -> cache empty list to indicate all tokens supported
      if (tokensField is String) {
        if (tokensField.toLowerCase() == 'all') {
          _tokensCache[pathChainId] =
              _tokensCache[pathChainId] ?? <TokenPathInfo>[];
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
              printV('Token parse error on chain $pathChainId: $e : $token');
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
    final bySymbol = <String, TokenPathInfo>{
      for (final t in existing) t.symbol: t
    };

    for (final t in incoming) {
      final cur = bySymbol[t.symbol];
      if (cur == null) {
        bySymbol[t.symbol] = t;
      } else {
        // If incoming has a real address/decimals, prefer it
        final hasBetterAddr = (t.address != null && t.address!.isNotEmpty) &&
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
      'ZZEC' => 'ZEC',
      _ => name,
    };
  }

  String _getTokenAddress({
    required CryptoCurrency currency,
    required Chain chain,
  }) {
    final symbol = _normalizeCakeNativeTokenName(currency.title);
    final list = _tokensCache[chain.chainId];

    // Try cache hit
    if (list != null && list.isNotEmpty) {
      for (final t in list) {
        if (t.symbol == symbol && t.address != null && t.address!.isNotEmpty) {
          return t.address!;
        } else if (t.symbol == symbol && (t.address == null)) {
          // Native token on this chain
          return '0x0000000000000000000000000000000000000000';
        }
      }
    }

    // May fail for non-native Alt-VM assets
    return symbol;
  }

  Map<String, dynamic>? findTokenBySymbol(
      {required String title, required List<dynamic> tokens}) {
    final reqSymbol = title.toUpperCase();
    for (final token in tokens) {
      final map = token as Map<String, dynamic>;
      final symbol = (map['symbol'] as String?)?.toUpperCase();
      if (symbol == reqSymbol) return map;
    }
    return null;
  }

  Chain _findChainByCurrency(CryptoCurrency cur, List<Chain> chains) {
    final network = _normalizeCakeNetwork(cur.tag ?? cur.title);
    return chains.firstWhere(
      (c) => c.name.toUpperCase() == network,
      orElse: () => throw Exception('Unsupported chain for ${cur.title}'),
    );
  }

  String _normalizeCakeNetwork(String network) {
    return switch (network.toUpperCase()) {
      'ETH' => 'ETHEREUM',
      'BSC' => 'BNB SMART CHAIN',
      'POL' => 'POLYGON',
      'AVAXC' => 'AVALANCHE',
      'TRX' => 'TRON',
      'SOL' => 'SOLANA',
      'CRO' => 'CRONOS',
      'ADA' => 'CARDANO',
      'KAS' => 'KASPA',
      'TON' => 'TONCOIN',
      'BCH' => 'BITCOIN CASH',
      _ => network.toUpperCase(),
    };
  }

  int? _parseUnixSeconds(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) {
      final clean = _stripN(value);
      return int.tryParse(clean);
    }
    return null;
  }

  String _stripN(String? str) {
    final s = str ?? '0';
    return s.endsWith('n') ? s.substring(0, s.length - 1) : s;
  }
}

class TokenPathInfo {
  final String symbol;
  final String? address;
  final int? decimals;
  final String? minAmount;
  final String? maxAmount;

  TokenPathInfo({
    required this.symbol,
    required this.address,
    required this.decimals,
    required this.minAmount,
    required this.maxAmount,
  });

  factory TokenPathInfo.fromJson(Map<String, dynamic> json) => TokenPathInfo(
        symbol: (json['symbol'] as String?)?.toUpperCase() ?? '',
        address: json['address'] as String?,
        decimals: json['decimals'] as int?,
        minAmount: json['minAmount']?.toString(),
        maxAmount: json['maxAmount']?.toString(),
      );
}

class Chain {
  final int chainId;
  final String name;
  final String vmId;

  Chain({
    required this.chainId,
    required this.name,
    required this.vmId,
  });

  factory Chain.fromJson(Map<String, dynamic> json) {
    return Chain(
      chainId: json['chainId'] as int,
      name: json['name'] as String,
      vmId: json['vmId'] as String,
    );
  }
}

class _PathInfo {
  final bool supportsExactOut;
  final String minToAmountHuman;

  _PathInfo({required this.supportsExactOut, required this.minToAmountHuman});
}
