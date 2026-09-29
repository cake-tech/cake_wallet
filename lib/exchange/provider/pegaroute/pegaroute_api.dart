import 'dart:convert';
import 'pegaroute_solana_wire.dart';
import 'package:blockchain_utils/blockchain_utils.dart' show Base58Decoder;

import 'package:http/http.dart' as very_insecure_http_do_not_use;

import 'package:cw_core/utils/proxy_wrapper.dart';

import 'pegaroute_configuration.dart';

// Pegaroute contract target: v0.5.3, not the version of a running proxy.
// Last compatibility review: 177d6891aada4659ca9d24cf3de8cb336ce31442.
// The version-label update does not establish a new audit or deployment.

typedef PegarouteGet = Future<very_insecure_http_do_not_use.Response> Function(
    Uri uri, Map<String, String> headers);
typedef PegaroutePost = Future<very_insecure_http_do_not_use.Response> Function(
  Uri uri,
  Map<String, String> headers,
  String body,
);

class PegarouteCodecException implements Exception {
  const PegarouteCodecException(this.message);

  final String message;

  @override
  String toString() => 'Pegaroute codec error: $message';
}

class PegarouteUnavailableException implements Exception {
  const PegarouteUnavailableException();

  @override
  String toString() => 'Pegaroute execution is unavailable';
}

final class PegarouteSwapAttemptException implements Exception {
  const PegarouteSwapAttemptException({
    required this.cause,
    required this.userMessage,
    this.providerTransactionId,
  });

  final Object cause;
  final String? providerTransactionId;

  /// Local validation diagnostics only; never dump arbitrary transport/provider bodies.
  String get diagnosticMessage {
    var underlying = cause;
    while (underlying is PegarouteSwapAttemptException) {
      underlying = underlying.cause;
    }
    return switch (underlying) {
      PegarouteCodecException error => error.message,
      _ => underlying.runtimeType.toString(),
    };
  }

  final String userMessage;

  @override
  String toString() => userMessage;
}

final class PegarouteApiError implements Exception {
  const PegarouteApiError._({
    required this.httpStatus,
    required this.code,
    required this.userMessage,
    this.provider,
    this.minAmount,
  });

  factory PegarouteApiError.fromJson(int httpStatus, Object? value) {
    final root = _object(value);
    final error = _object(root['error']);
    final detailsValue = error['details'];
    if (error.containsKey('details') && (detailsValue == null || detailsValue is! Map)) {
      throw const PegarouteCodecException('details must be an object');
    }
    final receivedCode = _requiredString(error, 'code');
    final code = publicCodes.contains(receivedCode) ? receivedCode : 'HTTP_ERROR';
    final minAmount = minimum(error);
    // Errors cannot supply replacement quotes or permission to retry creation.
    // Keep only the public code and numeric minimum; discard upstream prose.
    return PegarouteApiError._(
      httpStatus: httpStatus,
      code: code,
      userMessage: 'Pegaroute $code${minAmount == null ? '' : '; minimum: $minAmount'}',
      provider: _optionalString(error, 'provider'),
      minAmount: minAmount,
    );
  }

  static const publicCodes = {'CHAIN_DISABLED', 'CHAIN_HALTED', 'QUOTE_EXPIRED', 'AMOUNT_TOO_LOW',
    'SLIPPAGE_EXCEEDED', 'PROVIDER_UNAVAILABLE', 'UNSUPPORTED_PAIR', 'RATE_LIMITED',
    'INVALID_ADDRESS', 'INVALID_AMOUNT', 'AMOUNT_PRECISION_EXCEEDED', 'MEMO_TOO_LONG',
    'MISSING_QUOTE_DATA', 'PROVIDER_CHANGED', 'QUOTE_MISMATCH', 'INTERNAL_ERROR'};

  static double? limit(Object? value) {
    if (value is! String && value is! num) return null;
    final number = double.tryParse(value.toString());
    return number != null && number.isFinite && number >= 0 ? number : null;
  }

  static double? minimum(Map<dynamic, dynamic> error) {
    final details = error['details'];
    if (details is Map && limit(details['minAmount']) != null) return limit(details['minAmount']);
    final message = error['userMessage'] ?? error['message'];
    if (message is! String || message.length > 2048) return null;
    final match = RegExp(r'minimum\s*:\s*([0-9]+(?:\.[0-9]+)?)', caseSensitive: false).firstMatch(message);
    return limit(match?.group(1));
  }

  final int httpStatus;
  final String code;
  final String userMessage;
  final String? provider;
  final double? minAmount;

  @override
  String toString() => 'PegarouteApiError($httpStatus, $code)';
}

final class PegaroutePrivateValue {
  factory PegaroutePrivateValue(Object value) {
    if (value is bool) return PegaroutePrivateValue._(value);
    if (value is String && value.trim().isNotEmpty && value.length <= 64) {
      return PegaroutePrivateValue._(value);
    }
    throw const PegarouteCodecException('private must be a boolean or non-empty string');
  }

  const PegaroutePrivateValue._(this.value);

  factory PegaroutePrivateValue.fromJson(Object? value) {
    if (value == null) {
      throw const PegarouteCodecException('private must be a boolean or non-empty string');
    }
    return PegaroutePrivateValue(value);
  }

  final Object value;

  // Only an omitted value or boolean false is public. In particular, a
  // provider-declared string must never be interpreted by truthiness.
  bool get isEnabled => value != false;

}

final class PegarouteQuoteRequest {
  PegarouteQuoteRequest({
    required String fromChain,
    required String fromToken,
    required String toChain,
    required String toToken,
    required String amount,
    String? destinationAddress,
    String? senderAddress,
    String? refundAddress,
  })  : fromChain = _requiredRequestId(fromChain, 'fromChain'),
        fromToken = _requiredRequestId(fromToken, 'fromToken'),
        toChain = _requiredRequestId(toChain, 'toChain'),
        toToken = _requiredRequestId(toToken, 'toToken'),
        amount = _positiveAmount(amount),
        destinationAddress = _optionalRequestId(destinationAddress, 'destinationAddress'),
        senderAddress = _normalizeRequestSender(senderAddress),
        refundAddress = _normalizeRequestRefund(
          fromChain,
          _normalizeRequestSender(senderAddress),
          refundAddress,
        );

  final String fromChain;
  final String fromToken;
  final String toChain;
  final String toToken;
  final String amount;
  final String? destinationAddress;
  final String? senderAddress;
  final String? refundAddress;
  Map<String, String> toQuery() => _requestQuery(
        fromChain: fromChain,
        fromToken: fromToken,
        toChain: toChain,
        toToken: toToken,
        amount: amount,
        destinationAddress: destinationAddress,
        senderAddress: senderAddress,
        refundAddress: refundAddress,
      );
}

final class PegarouteSwapRequest {
  PegarouteSwapRequest({
    required String fromChain,
    required String fromToken,
    required String toChain,
    required String toToken,
    required String amount,
    required String destinationAddress,
    required String senderAddress,
    String? refundAddress,
    String? quoteId,
    String? routeProvider,
  })  : fromChain = _requiredRequestId(fromChain, 'fromChain'),
        fromToken = _requiredRequestId(fromToken, 'fromToken'),
        toChain = _requiredRequestId(toChain, 'toChain'),
        toToken = _requiredRequestId(toToken, 'toToken'),
        amount = _positiveAmount(amount),
        destinationAddress = _requiredRequestId(destinationAddress, 'destinationAddress'),
        senderAddress = _requiredRequestId(senderAddress, 'senderAddress'),
        refundAddress = _normalizeRequestRefund(
          fromChain,
          _normalizeRequestSender(senderAddress),
          refundAddress,
        ),
        quoteId = _optionalRequestId(quoteId, 'quoteId'),
        routeProvider = _optionalRequestId(routeProvider, 'routeProvider');

  final String fromChain;
  final String fromToken;
  final String toChain;
  final String toToken;
  final String amount;
  final String destinationAddress;
  final String senderAddress;
  final String? refundAddress;
  final String? quoteId;
  final String? routeProvider;

  Map<String, dynamic> toJson() => {
        ..._requestQuery(
          fromChain: fromChain,
          fromToken: fromToken,
          toChain: toChain,
          toToken: toToken,
          amount: amount,
          destinationAddress: destinationAddress,
          senderAddress: senderAddress,
          refundAddress: refundAddress,
        ),
        if (quoteId != null) 'quoteId': quoteId,
        if (routeProvider != null) 'routeProvider': routeProvider,
      };
}

/// Validate once at construction. Final value types cannot change before encoding.
final class PegarouteTokenAmount {
  PegarouteTokenAmount({required this.display, required this.baseUnits}) {
    if (!RegExp(r'^[0-9]+$').hasMatch(baseUnits) || !_isDecimal(display)) {
      throw const PegarouteCodecException('invalid token amount');
    }
  }

  factory PegarouteTokenAmount.fromJson(Object? value) {
    final map = _object(value);
    return PegarouteTokenAmount(
      display: _requiredString(map, 'display'),
      baseUnits: _requiredString(map, 'baseUnits'),
    );
  }

  final String display;
  final String baseUnits;

  Map<String, String> toJson() => {'display': display, 'baseUnits': baseUnits};
}

final class PegarouteEvmApproval {
  PegarouteEvmApproval({
    required this.spender,
    required this.tokenAddress,
    required this.amount,
  }) {
    if (spender.isEmpty || tokenAddress.isEmpty) {
      throw const PegarouteCodecException('approval addresses are required');
    }
  }

  factory PegarouteEvmApproval.fromJson(Object? value) {
    final map = _object(value);
    return PegarouteEvmApproval(
      spender: _requiredString(map, 'spender'),
      tokenAddress: _requiredString(map, 'tokenAddress'),
      amount: PegarouteTokenAmount.fromJson(map['amount']),
    );
  }

  final String spender;
  final String tokenAddress;
  final PegarouteTokenAmount amount;

  Map<String, dynamic> toJson() => {
        'spender': spender,
        'tokenAddress': tokenAddress,
        'amount': amount.toJson(),
      };
}

final class PegarouteExecution {
  PegarouteExecution({
    required this.family,
    required this.mode,
    this.chainId,
    this.chain,
    this.to,
    this.data,
    this.value,
    this.gasLimit,
    this.memo,
    this.approval,
    this.amount,
    this.transferAmount,
    this.serializedTransaction,
    this.encoding,
    this.minOut,
    this.gasRate,
  }) {
    _validate();
  }

  factory PegarouteExecution.fromJson(Object? value) {
    final map = _object(value);
    final family = _requiredString(map, 'family');
    final mode = _requiredString(map, 'mode');
    _rejectUnknown(map, _executionKeys(family, mode));
    late final PegarouteExecution execution;
    if (family == 'evm') {
      execution = PegarouteExecution(
        family: family,
        mode: mode,
        chainId: _requiredInt(map, 'chainId'),
        to: _requiredString(map, 'to'),
        data: _requiredNullableString(map, 'data'),
        value: _requiredNullableTokenAmount(map, 'value'),
        gasLimit: _requiredNullableString(map, 'gasLimit'),
        memo: _requiredNullableString(map, 'memo'),
        approval: _requiredNullableApproval(map, 'approval'),
        transferAmount: _requiredNullableTokenAmount(map, 'transferAmount'),
      );
    } else if (family == 'utxo') {
      execution = PegarouteExecution(
        family: family,
        mode: mode,
        to: _requiredString(map, 'to'),
        amount: PegarouteTokenAmount.fromJson(map['amount']),
        memo: _requiredNullableString(map, 'memo'),
        gasRate: _requiredNullableString(map, 'gasRate'),
      );
    } else if (family == 'solana' && mode == 'serialized-tx') {
      execution = PegarouteExecution(
        family: family,
        mode: mode,
        serializedTransaction: _requiredString(map, 'serializedTransaction'),
        encoding: _requiredString(map, 'encoding'),
        minOut: _requiredNullableTokenAmount(map, 'minOut'),
      );
    } else if (const {'solana', 'tron', 'other'}.contains(family)) {
      execution = PegarouteExecution(
        family: family,
        mode: mode,
        chain: family == 'other' ? _requiredString(map, 'chain') : null,
        to: _requiredString(map, 'to'),
        amount: PegarouteTokenAmount.fromJson(map['amount']),
        memo: _requiredNullableString(map, 'memo'),
      );
    } else {
      throw const PegarouteCodecException('unsupported execution family');
    }
    return execution;
  }

  final String family;
  final String mode;
  final int? chainId;
  final String? chain;
  final String? to;
  final String? data;
  final PegarouteTokenAmount? value;
  final String? gasLimit;
  final String? memo;
  final PegarouteEvmApproval? approval;
  final PegarouteTokenAmount? amount;
  final PegarouteTokenAmount? transferAmount;
  final String? serializedTransaction;
  final String? encoding;
  final PegarouteTokenAmount? minOut;
  final String? gasRate;

  void _validate() {
    if (encoding != null && (family != 'solana' || mode != 'serialized-tx')) {
      _invalid('encoding outside Solana serialized execution');
    }
    if (family == 'evm') {
      if (chain != null ||
          amount != null ||
          serializedTransaction != null ||
          minOut != null ||
          gasRate != null) {
        _invalid('EVM execution fields');
      }
      if (chainId == null || to == null || to!.isEmpty) _invalid('EVM destination');
      switch (mode) {
        case 'contract-call':
          if (!_validCalldata(data) || transferAmount != null) {
            _invalid('EVM call data');
          }
          break;
        case 'native-transfer':
          if (value == null || data != null || approval != null || transferAmount != null) {
            _invalid('EVM native transfer');
          }
          break;
        case 'erc20-transfer':
          if (transferAmount == null || value != null || approval != null || data != null) {
            _invalid('EVM token transfer');
          }
          break;
        default:
          _invalid('unknown EVM mode');
      }
      return;
    }
    if (family == 'utxo' && mode == 'payment-with-memo') {
      if (chainId != null ||
          chain != null ||
          data != null ||
          value != null ||
          gasLimit != null ||
          approval != null ||
          transferAmount != null ||
          serializedTransaction != null ||
          minOut != null) _invalid('UTXO execution fields');
      _requireTransfer();
      return;
    }
    if (const {'solana', 'tron', 'other'}.contains(family) &&
        mode == 'deposit-transfer') {
      if (chainId != null ||
          data != null ||
          value != null ||
          gasLimit != null ||
          approval != null ||
          transferAmount != null ||
          serializedTransaction != null ||
          minOut != null ||
          gasRate != null ||
          (family != 'other' && chain != null)) _invalid('deposit execution fields');
      _requireTransfer();
      if (family == 'other' && (chain == null || chain!.isEmpty)) _invalid('deposit chain');
      return;
    }
    if (family == 'solana' && mode == 'serialized-tx') {
      if (chainId != null ||
          chain != null ||
          to != null ||
          data != null ||
          value != null ||
          gasLimit != null ||
          memo != null ||
          approval != null ||
          amount != null ||
          transferAmount != null ||
          gasRate != null) {
        _invalid('serialized execution fields');
      }
      if (serializedTransaction == null || serializedTransaction!.isEmpty) {
        _invalid('serialized transaction');
      }
      if (!isValidPegarouteSolanaTransaction(serializedTransaction!, encoding)) {
        _invalid('serialized transaction encoding');
      }
      return;
    }
    _invalid('unsupported execution family/mode');
  }

  void _requireTransfer() {
    if (to == null || to!.isEmpty || amount == null) _invalid('transfer destination/amount');
  }

  Map<String, dynamic> toJson() {
    return {
      'family': family,
      'mode': mode,
      if (family == 'evm') ...{
        'chainId': chainId,
        'to': to,
        'data': data,
        'value': value?.toJson(),
        'gasLimit': gasLimit,
        'memo': memo,
        'approval': approval?.toJson(),
        'transferAmount': transferAmount?.toJson(),
      },
      if (family == 'utxo') ...{
        'to': to,
        'amount': amount?.toJson(),
        'memo': memo,
        'gasRate': gasRate,
      },
      if (family == 'solana' && mode == 'serialized-tx') ...{
        'serializedTransaction': serializedTransaction,
        'encoding': encoding,
        'minOut': minOut?.toJson(),
      },
      if (const {'solana', 'tron', 'other'}.contains(family) && mode == 'deposit-transfer') ...{
        if (family == 'other') 'chain': chain,
        'to': to,
        'amount': amount?.toJson(),
        'memo': memo,
      },
    };
  }
}

Set<String> _executionKeys(String family, String mode) {
  if (family == 'evm') {
    return const {
      'family',
      'mode',
      'chainId',
      'to',
      'data',
      'value',
      'gasLimit',
      'memo',
      'approval',
      'transferAmount',
    };
  }
  if (family == 'utxo' && mode == 'payment-with-memo') {
    return const {'family', 'mode', 'to', 'amount', 'memo', 'gasRate'};
  }
  if (family == 'solana' && mode == 'serialized-tx') {
    return const {'family', 'mode', 'serializedTransaction', 'minOut', 'encoding'};
  }
  if (const {'solana', 'tron'}.contains(family) &&
      mode == 'deposit-transfer') {
    return const {'family', 'mode', 'to', 'amount', 'memo'};
  }
  if (family == 'other' && mode == 'deposit-transfer') {
    return const {'family', 'mode', 'chain', 'to', 'amount', 'memo'};
  }
  return const {'family', 'mode'};
}

final class PegarouteRoute {
  PegarouteRoute({
    required this.provider,
    required this.expectedOutput,
    this.providerType,
    this.subprovider,
    this.privateValue,
    this.memo,
    this.inboundAddress,
    this.router,
    this.minAmount,
    this.estimatedTimeSeconds,
    this.fees,
    this.expiry,
    this.gasRate,
    Map<String, dynamic>? resolvedFee,
    this.openOceanRoute,
    Set<String>? presentFields,
  }) : resolvedFee = resolvedFee == null ? null : _freezeJsonMap(resolvedFee),
       presentFields = Set.unmodifiable(presentFields ?? const {});

  factory PegarouteRoute.fromJson(Object? value) {
    final map = _object(value);
    // Accept additive response metadata; known fields keep their typed contract.
    return PegarouteRoute(
      provider: _requiredString(map, 'provider'),
      providerType: _requiredString(map, 'providerType'),
      expectedOutput: _requiredString(map, 'expectedOutput'),
      subprovider: _optionalString(map, 'subprovider'),
      privateValue:
          map.containsKey('private') ? PegaroutePrivateValue.fromJson(map['private']) : null,
      memo: _requiredNullableString(map, 'memo'),
      inboundAddress: _requiredNullableString(map, 'inboundAddress'),
      router: _requiredNullableString(map, 'router'),
      gasRate: _requiredNullableString(map, 'gasRate'),
      minAmount: _requiredNullableString(map, 'minAmount'),
      estimatedTimeSeconds: _requiredNum(map, 'estimatedTimeSeconds'),
      expiry: _requiredNullableStringOrNum(map, 'expiry'),
      fees: PegarouteFees.fromJson(map['fees']),
      resolvedFee: _resolvedFee(map['resolvedFee']),
      openOceanRoute: map.containsKey('openOceanRoute')
          ? PegarouteOpenOceanRoute.fromJson(map['openOceanRoute'])
          : null,
      presentFields: map.keys.toSet(),
    );
  }

  factory PegarouteRoute.fromRouteInfoJson(Object? value) {
    final map = _object(value);
    return PegarouteRoute(
      provider: _requiredString(map, 'provider'),
      expectedOutput: _requiredString(map, 'expectedOutput'),
      subprovider: _optionalString(map, 'subprovider'),
      privateValue:
          map.containsKey('private') ? PegaroutePrivateValue.fromJson(map['private']) : null,
      estimatedTimeSeconds: _requiredNum(map, 'estimatedTimeSeconds'),
      fees: PegarouteFees.fromJson(map['fees']),
      openOceanRoute: map.containsKey('openOceanRoute')
          ? PegarouteOpenOceanRoute.fromJson(map['openOceanRoute'])
          : null,
      presentFields: map.keys.toSet(),
    );
  }

  final String provider;
  final String expectedOutput;
  final String? providerType;
  final String? subprovider;
  final PegaroutePrivateValue? privateValue;
  final String? memo;
  final String? inboundAddress;
  final String? router;
  final String? minAmount;
  final num? estimatedTimeSeconds;
  final PegarouteFees? fees;
  final Object? expiry;
  final String? gasRate;
  final Map<String, dynamic>? resolvedFee;
  final PegarouteOpenOceanRoute? openOceanRoute;
  final Set<String> presentFields;
}

final class PegarouteOpenOceanRoute {
  PegarouteOpenOceanRoute({this.dexId, this.dexCode, List<PegarouteOpenOceanDex>? dexes})
      : dexes = dexes == null ? null : List.unmodifiable(dexes);

  factory PegarouteOpenOceanRoute.fromJson(Object? value) {
    final map = _object(value);
    final hasDexes = map.containsKey('dexes');
    final dexesValue = map['dexes'];
    if (hasDexes && (dexesValue == null || dexesValue is! List)) {
      throw const PegarouteCodecException('openOceanRoute.dexes must be an array');
    }
    return PegarouteOpenOceanRoute(
      dexId: _optionalInt(map, 'dexId'),
      dexCode: _optionalString(map, 'dexCode'),
      dexes: !hasDexes
          ? null
          : (dexesValue as List).map((item) {
              final dex = _object(item);
              return PegarouteOpenOceanDex(
                dexId: _optionalInt(dex, 'dexId'),
                dexCode: _optionalString(dex, 'dexCode'),
              );
            }).toList(growable: false),
    );
  }

  final int? dexId;
  final String? dexCode;
  final List<PegarouteOpenOceanDex>? dexes;
}

class PegarouteOpenOceanDex {
  const PegarouteOpenOceanDex({this.dexId, this.dexCode});

  final int? dexId;
  final String? dexCode;
}

class PegarouteFees {
  const PegarouteFees({
    this.affiliate,
    this.liquidity,
    this.outbound,
    this.subAffiliate,
    this.total,
    this.totalBps,
    this.slippageBps,
  });

  factory PegarouteFees.fromJson(Object? value) {
    final map = _object(value);
    return PegarouteFees(
      affiliate: _requiredString(map, 'affiliate'),
      liquidity: _requiredString(map, 'liquidity'),
      outbound: _requiredString(map, 'outbound'),
      subAffiliate: _optionalString(map, 'subAffiliate'),
      total: _requiredString(map, 'total'),
      totalBps: _optionalNum(map, 'totalBps'),
      slippageBps: _optionalNum(map, 'slippageBps'),
    );
  }

  final String? affiliate;
  final String? liquidity;
  final String? outbound;
  final String? subAffiliate;
  final String? total;
  final num? totalBps;
  final num? slippageBps;
}

class PegarouteWarning {
  const PegarouteWarning({
    required this.provider,
    required this.code,
    required this.message,
    required this.userMessage,
  });

  factory PegarouteWarning.fromJson(Object? value) {
    final map = _object(value);
    return PegarouteWarning(
      provider: _requiredPresentString(map, 'provider'),
      code: _requiredString(map, 'code'),
      message: _requiredString(map, 'message'),
      userMessage: _requiredString(map, 'userMessage'),
    );
  }

  final String provider;
  final String code;
  final String message;
  final String userMessage;
}

final class PegarouteQuoteResponse {
  PegarouteQuoteResponse({
    required this.quoteId,
    required this.expiresAt,
    required List<PegarouteRoute> routes,
    required List<PegarouteWarning> warnings,
  }) : routes = List.unmodifiable(routes),
       warnings = List.unmodifiable(warnings);

  factory PegarouteQuoteResponse.fromJson(Object? value) {
    final map = _object(value);
    return PegarouteQuoteResponse(
      quoteId: _requiredString(map, 'quoteId'),
      expiresAt: _requiredString(map, 'expiresAt'),
      routes: _list(map, 'routes').map(PegarouteRoute.fromJson).toList(),
      warnings: _list(map, 'warnings').map(PegarouteWarning.fromJson).toList(),
    );
  }

  final String quoteId;
  final String expiresAt;
  final List<PegarouteRoute> routes;
  final List<PegarouteWarning> warnings;
}

final class _PegarouteApiCapability {
  const _PegarouteApiCapability();
}

final class PegarouteValidatedQuote {
  const PegarouteValidatedQuote._({
    required this.requestJson,
    required this.response,
    required _PegarouteApiCapability capability,
    required Uri origin,
  })  : _capability = capability,
        _origin = origin;

  final String requestJson;
  final PegarouteQuoteResponse response;
  final _PegarouteApiCapability _capability;
  final Uri _origin;

  // The token is never exposed; this only lets the binding library verify its
  // provenance without being able to manufacture one.
  bool isBoundTo(Object client) =>
      client is PegarouteApiClient &&
      identical(_capability, client._capability) &&
      _origin == client.configuration.origin;
}

final class PegarouteProviderInfo {
  PegarouteProviderInfo({required this.name, this.referenceId, Object? details})
      : details = _freezeJsonValue(details);

  factory PegarouteProviderInfo.fromJson(Object? value) {
    final map = _object(value);
    return PegarouteProviderInfo(
      name: _requiredString(map, 'name'),
      referenceId: _requiredNullableString(map, 'referenceId'),
      details: map['details'],
    );
  }

  final String name;
  final String? referenceId;
  final Object? details;

  PegarouteInstaswapSnapshot? get instaswapSwapLite {
    final value = details is Map ? (details as Map)['instaswapSwapLite'] : null;
    return value == null ? null : PegarouteInstaswapSnapshot.fromJson(value);
  }
}

/// Only deposit identity, exact amount, and expiry affect the Cake order.
final class PegarouteInstaswapSnapshot {
  const PegarouteInstaswapSnapshot._({
    required this.txid,
    required this.depositAddress,
    this.depositAmountExact,
    this.expiresAt,
  });

  factory PegarouteInstaswapSnapshot.fromJson(Object? value) {
    final map = _object(value);
    return PegarouteInstaswapSnapshot._(
      txid: _requiredString(map, 'txid'),
      depositAddress: _requiredString(map, 'depositAddress'),
      depositAmountExact: _optionalString(map, 'depositAmountExact'),
      expiresAt: _optionalNullableString(map, 'expiresAt'),
    );
  }

  final String txid;
  final String depositAddress;
  final String? depositAmountExact;
  final String? expiresAt;
}

class PegarouteRefund {
  const PegarouteRefund({
    required this.status,
    required this.chain,
    required this.amount,
    required this.originalAmount,
    required this.feeDeducted,
    required this.feeDescription,
    required this.refundAddress,
    this.txHash,
    this.completedAt,
  });

  factory PegarouteRefund.fromJson(Object? value) {
    final map = _object(value);
    final status = _requiredString(map, 'status');
    if (!const {'pending', 'broadcasting', 'completed'}.contains(status)) {
      throw const PegarouteCodecException('refund status is invalid');
    }
    return PegarouteRefund(
      status: status,
      chain: _requiredString(map, 'chain'),
      amount: _requiredString(map, 'amount'),
      originalAmount: _requiredString(map, 'originalAmount'),
      feeDeducted: _requiredString(map, 'feeDeducted'),
      feeDescription: _requiredString(map, 'feeDescription'),
      refundAddress: _requiredString(map, 'refundAddress'),
      txHash: _optionalString(map, 'txHash'),
      completedAt: _optionalString(map, 'completedAt'),
    );
  }

  final String status;
  final String chain;
  final String amount;
  final String originalAmount;
  final String feeDeducted;
  final String feeDescription;
  final String refundAddress;
  final String? txHash;
  final String? completedAt;
}

// Decode only status fields used for order binding, progress, and refund display.
// Unused service metadata cannot authorize a payment or replace refund evidence.
class PegarouteStatusResponse {
  const PegarouteStatusResponse({
    required this.transactionId,
    required this.status,
    required this.internalStatus,
    required this.input,
    required this.output,
    required this.route,
    this.refund,
    this.execution,
    this.provider,
  });

  factory PegarouteStatusResponse.fromJson(Object? value) {
    final map = _object(value);
    final status = _requiredString(map, 'status');
    final internalStatus = _requiredString(map, 'internalStatus');
    if (!const {'pending', 'executing', 'success', 'fail'}.contains(status)) {
      throw const PegarouteCodecException('status is invalid');
    }
    if (!const {
      'pending',
      'submitted',
      'executing',
      'confirming',
      'completed',
      'failed',
      'refunded',
    }.contains(internalStatus)) {
      throw const PegarouteCodecException('internalStatus is invalid');
    }
    final refundValue = _requiredNullableValue(map, 'refund');
    final route = PegarouteRoute.fromRouteInfoJson(map['route']);
    final provider =
        map.containsKey('provider') ? PegarouteProviderInfo.fromJson(map['provider']) : null;
    if (provider != null && provider.name != route.provider) {
      throw const PegarouteCodecException('route and provider identities disagree');
    }
    return PegarouteStatusResponse(
      transactionId: _requiredString(map, 'transactionId'),
      status: status,
      internalStatus: internalStatus,
      input: PegarouteStatusInput.fromJson(map['input']),
      output: PegarouteStatusOutput.fromJson(map['output']),
      route: route,
      refund: refundValue == null ? null : PegarouteRefund.fromJson(refundValue),
      execution:
          map.containsKey('execution') ? PegarouteExecution.fromJson(map['execution']) : null,
      provider: provider,
    );
  }

  final String transactionId;
  final String status;
  final String internalStatus;
  final PegarouteStatusInput input;
  final PegarouteStatusOutput output;
  final PegarouteRoute route;
  final PegarouteRefund? refund;
  final PegarouteExecution? execution;
  final PegarouteProviderInfo? provider;
}

class PegarouteStatusInput {
  const PegarouteStatusInput({
    required this.chain,
    required this.token,
    required this.amount,
    this.address,
    this.refundAddress,
    this.txHash,
    this.providerReferenceId,
    this.providerReferenceSupplied = false,
    this.instaswapSwapLite,
  });

  factory PegarouteStatusInput.fromJson(Object? value) {
    final map = _object(value);
    return PegarouteStatusInput(
      chain: _requiredString(map, 'chain'),
      token: _requiredString(map, 'token'),
      amount: _requiredString(map, 'amount'),
      address: _optionalString(map, 'address'),
      refundAddress: _optionalString(map, 'refundAddress'),
      txHash: _optionalString(map, 'txHash'),
      providerReferenceId: _optionalString(map, 'providerReferenceId'),
      providerReferenceSupplied: map.containsKey('providerReferenceId'),
      instaswapSwapLite: map.containsKey('instaswapSwapLite')
          ? PegarouteInstaswapSnapshot.fromJson(map['instaswapSwapLite'])
          : null,
    );
  }

  final String chain;
  final String token;
  final String amount;
  final String? address;
  final String? refundAddress;
  final String? txHash;
  final String? providerReferenceId;
  final bool providerReferenceSupplied;
  final PegarouteInstaswapSnapshot? instaswapSwapLite;
}

class PegarouteStatusOutput {
  const PegarouteStatusOutput({
    required this.chain,
    required this.token,
    required this.address,
    this.amount,
    this.txHash,
  });

  factory PegarouteStatusOutput.fromJson(Object? value) {
    final map = _object(value);
    return PegarouteStatusOutput(
      chain: _requiredString(map, 'chain'),
      token: _requiredString(map, 'token'),
      address: _requiredString(map, 'address'),
      amount: _optionalString(map, 'amount'),
      txHash: _optionalString(map, 'txHash'),
    );
  }

  final String chain;
  final String token;
  final String address;
  final String? amount;
  final String? txHash;
}

/// A one-use POST capability for this client's exact public quote intent.
/// Wallet intent belongs to the provider's creation context, not TradeRequest.
final class PegarouteValidatedSwapPreflight {
  PegarouteValidatedSwapPreflight._(this.quote, this.route, this.requestJson);

  final PegarouteValidatedQuote quote;
  final PegarouteRoute route;
  final String requestJson;
  bool _consumed = false;

  void consumeFor(Object client, DateTime at) {
    final expiry = pegarouteRouteDeadline(route.expiry);
    if (_consumed || !quote.isBoundTo(client) ||
        !at.isBefore(DateTime.parse(quote.response.expiresAt)) ||
        (expiry != null && !at.isBefore(expiry))) {
      throw const PegarouteCodecException('Quote expired, consumed or belongs to another client');
    }
    _consumed = true;
  }
}

DateTime? pegarouteRouteDeadline(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toUtc();
  } else if (value is num && value.isFinite && value >= 0 && value <= 8640000000000) {
    return DateTime.fromMillisecondsSinceEpoch((value * 1000).round(), isUtc: true);
  }
  throw const PegarouteCodecException('Invalid route deadline');
}

class PegarouteApiClient {
  PegarouteApiClient({
    PegarouteConfiguration? configuration,
    PegarouteGet? get,
    PegaroutePost? post,
    DateTime Function()? clock,
    // The server allows ten seconds for each route provider, plus transport time.
    this.readTimeout = const Duration(seconds: 12),
  })  : configuration = configuration ?? PegarouteConfiguration.generated(),
        _get = get ?? ((uri, headers) => ProxyWrapper().get(clearnetUri: uri, headers: headers)),
        _post = post ??
            ((uri, headers, body) =>
                ProxyWrapper().post(clearnetUri: uri, headers: headers, body: body)),
        _clock = clock;

  final PegarouteConfiguration configuration;
  // Bound reads only. A timed-out creation POST must never be retried automatically.
  final Duration readTimeout;
  final PegarouteGet _get;
  final PegaroutePost _post;
  final DateTime Function()? _clock;
  final _PegarouteApiCapability _capability = _PegarouteApiCapability();

  Map<String, String> get _headers => const {};

  Uri _uri(String path, [Map<String, String>? query]) {
    final origin = configuration.origin;
    if (origin == null) throw const PegarouteUnavailableException();
    return origin.replace(path: path, queryParameters: query);
  }

  Future<PegarouteValidatedQuote> quote(PegarouteQuoteRequest request) async {
    final query = request.toQuery();
    final requestJson = json.encode({
      ...query,
      // Cake requests public quotes only. The returned route must also be public.
      'private': false,
    });
    final origin = _origin;
    final response = await _get(origin.replace(path: '/quote', queryParameters: query), _headers)
        .timeout(readTimeout);
    final quote = _decode(response, PegarouteQuoteResponse.fromJson, expectedStatus: 200);
    return PegarouteValidatedQuote._(
      requestJson: requestJson,
      response: quote,
      capability: _capability,
      origin: origin,
    );
  }

  Future<Set<String>> chains() async {
    final response = await _get(_uri('/chains'), _headers).timeout(readTimeout);
    return _decode(response, (value) => _catalogIds(_object(value), 'chains'), expectedStatus: 200);
  }

  Future<Set<String>> tokens(String chain) async {
    final normalized = chain.trim();
    if (normalized.isEmpty) throw const PegarouteCodecException('chain must not be blank');
    final response = await _get(_uri('/tokens', {'chain': normalized}), _headers).timeout(readTimeout);
    return _decode(response, (value) {
      final map = _object(value);
      if (_requiredString(map, 'chain') != normalized) {
        throw const PegarouteCodecException('Catalog chain changed');
      }
      return _catalogIds(map, 'tokens');
    }, expectedStatus: 200);
  }

  Future<PegarouteStatusResponse> status(String id) async {
    final normalized = id.trim();
    if (normalized.isEmpty) throw const PegarouteCodecException('id must not be blank');
    final response = await _get(_uri('/swap/$normalized'), _headers).timeout(readTimeout);
    return _decode(response, PegarouteStatusResponse.fromJson, expectedStatus: 200);
  }

  Future<void> notifySourceHash(String id, String hash, {String chain = 'ETH'}) async {
    final evm = const {'ETH', 'BSC', 'BASE', 'ARBITRUM', 'POLYGON'}.contains(chain);
    bool validHash;
    try {
      validHash = chain == 'SOL'
          ? Base58Decoder.decode(hash).length == 64
          : RegExp(evm ? r'^0x[0-9a-fA-F]{64}$' : r'^[0-9a-fA-F]{64}$').hasMatch(hash);
    } catch (_) {
      validHash = false;
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id) || !validHash) {
      throw const PegarouteCodecException('Invalid deposit notification identity');
    }
    final response = await _post(_uri('/swap/$id/txhash'),
        {..._headers, 'Content-Type': 'application/json'}, json.encode({'txHash': hash}));
    _decode(response, (value) {
      final map = _object(value);
      if (map['transactionId'] != id ||
          map['txHash'] is! String ||
          (chain == 'SOL'
              ? map['txHash'] != hash
              : (map['txHash'] as String).toLowerCase() != hash.toLowerCase()) ||
          !const {'submitted', 'executing', 'confirming', 'completed', 'failed', 'refunded'}
              .contains(map['status'])) {
        throw const PegarouteCodecException('Deposit notification identity changed');
      }
      return true;
    }, expectedStatus: 200);
    // The legacy submitted acknowledgement is not persistence evidence.
  }

  PegarouteValidatedSwapPreflight preflight({
    required PegarouteValidatedQuote quote,
    required PegarouteRoute route,
    required PegarouteSwapRequest request,
  }) {
    final quoted = _object(jsonDecode(quote.requestJson));
    final body = request.toJson();
    const fields = ['fromChain', 'fromToken', 'toChain', 'toToken', 'amount',
      'senderAddress', 'destinationAddress', 'refundAddress'];
    if (!quote.isBoundTo(this) || !quote.response.routes.contains(route) ||
        quoted['private'] != false || (route.privateValue?.isEnabled ?? false) ||
        request.quoteId != quote.response.quoteId || request.routeProvider != route.provider ||
        fields.any((key) => quoted[key] != body[key])) {
      throw const PegarouteCodecException('Swap request differs from the reviewed public quote');
    }
    return PegarouteValidatedSwapPreflight._(quote, route, jsonEncode(body));
  }

  Future<PegarouteValidatedSwapResult> swap(PegarouteValidatedSwapPreflight preflight) async {
    final current = (_clock ?? DateTime.now)().toUtc();
    // Only public intent can acquire a preflight. Canonical main accepts
    // private in the query only; never add it to the JSON body.
    final uri = _uri('/swap');
    final headers = {..._headers, 'Content-Type': 'application/json'};
    // This is deliberately the last synchronous operation before the first
    // POST. It remains consumed if the transport, provider, or response
    // decoder fails, so an ambiguous attempt cannot be replayed.
    preflight.consumeFor(this, current);
    try {
      final response = await _post(uri, headers, preflight.requestJson);
      final decoded = _decode(response, PegarouteSwapResponse.fromJson, expectedStatus: 202);
      return PegarouteValidatedSwapResult._(
        response: decoded,
        capability: _capability,
        origin: _origin,
      );
    } catch (error, stackTrace) {
      final message = error is PegarouteApiError
          ? error.userMessage
          : 'Pegaroute creation may have reached the server. Automatic retry is disabled.';
      Error.throwWithStackTrace(
        PegarouteSwapAttemptException(cause: error, userMessage: message),
        stackTrace,
      );
    }
  }

  Uri get _origin {
    final origin = configuration.origin;
    if (origin == null) throw const PegarouteUnavailableException();
    return origin;
  }

  T _decode<T>(
    very_insecure_http_do_not_use.Response response,
    T Function(Object?) decoder, {
    required int expectedStatus,
  }) {
    Object? value;
    try {
      value = _json(response.body);
    } on PegarouteCodecException {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PegarouteApiError._(
          httpStatus: response.statusCode,
          code: 'INVALID_RESPONSE',
          userMessage: 'The provider returned an invalid response',
        );
      }
      rethrow;
    }
    if (response.statusCode != expectedStatus) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw PegarouteCodecException('response must use HTTP $expectedStatus');
      }
      throw PegarouteApiError.fromJson(response.statusCode, value);
    }
    return decoder(value);
  }

  static Object? _json(String body) {
    try {
      return json.decode(body);
    } catch (_) {
      throw const PegarouteCodecException('response is not valid JSON');
    }
  }
}

class PegarouteSwapResponse {
  const PegarouteSwapResponse({
    required this.transactionId,
    required this.providerType,
    required this.route,
    required this.execution,
    required this.provider,
  });

  factory PegarouteSwapResponse.fromJson(Object? value) {
    final map = _object(value);
    final status = _requiredString(map, 'status');
    if (status != 'pending') throw const PegarouteCodecException('swap status must be pending');
    final route = PegarouteRoute.fromRouteInfoJson(map['route']);
    final provider = PegarouteProviderInfo.fromJson(map['provider']);
    if (route.provider != provider.name) {
      throw const PegarouteCodecException('route and provider identities disagree');
    }
    return PegarouteSwapResponse(
      transactionId: _requiredString(map, 'transactionId'),
      providerType: _requiredString(map, 'providerType'),
      route: route,
      execution: PegarouteExecution.fromJson(map['execution']),
      provider: provider,
    );
  }

  final String transactionId;
  final String providerType;
  final PegarouteRoute route;
  final PegarouteExecution execution;
  final PegarouteProviderInfo provider;
}

/// The constructor is private so callers cannot manufacture a result that did
/// not come from the validated preflight POST boundary.
final class PegarouteValidatedSwapResult {
  const PegarouteValidatedSwapResult._({
    required this.response,
    required _PegarouteApiCapability capability,
    required Uri origin,
  })  : _capability = capability,
        _origin = origin;

  final PegarouteSwapResponse response;
  final _PegarouteApiCapability _capability;
  final Uri _origin;

  bool isBoundTo(Object client) =>
      client is PegarouteApiClient &&
      identical(_capability, client._capability) &&
      _origin == client.configuration.origin;
}

Map<String, String> _requestQuery({
  required String fromChain,
  required String fromToken,
  required String toChain,
  required String toToken,
  required String amount,
  String? destinationAddress,
  String? senderAddress,
  String? refundAddress,
}) {
  if (refundAddress != null && senderAddress == null) {
    throw const PegarouteCodecException('refundAddress requires senderAddress');
  }
  // Both final request types validate and normalize their fields at construction.
  return {
    'fromChain': fromChain,
    'fromToken': fromToken,
    'toChain': toChain,
    'toToken': toToken,
    'amount': amount,
    if (destinationAddress != null) 'destinationAddress': destinationAddress,
    if (senderAddress != null) 'senderAddress': senderAddress,
    if (refundAddress != null) 'refundAddress': refundAddress,
  };
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map) throw const PegarouteCodecException('expected JSON object');
  return Map<String, dynamic>.from(value);
}

Map<String, dynamic> _freezeJsonMap(Map<String, dynamic> value) {
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    result[entry.key] = _freezeJsonValue(entry.value);
  }
  return Map.unmodifiable(result);
}

Object? _freezeJsonValue(Object? value) {
  if (value is Map) {
    return _freezeJsonMap(Map<String, dynamic>.from(value));
  }
  if (value is List) return List.unmodifiable(value.map(_freezeJsonValue));
  return value;
}

void _rejectUnknown(Map<String, dynamic> map, Set<String> allowed) {
  if (map.keys.any((key) => !allowed.contains(key))) {
    throw const PegarouteCodecException('object contains unknown fields');
  }
}

Set<String> _catalogIds(Map<String, dynamic> map, String key) =>
    Set.unmodifiable(_list(map, key).map((value) => _requiredString(_object(value), 'id')));

List<dynamic> _list(Map<String, dynamic> map, String key) {
  if (map[key] is! List) throw PegarouteCodecException('$key must be an array');
  return map[key] as List<dynamic>;
}

String _requiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty)
    throw PegarouteCodecException('$key must be a non-empty string');
  return value;
}

String _requiredPresentString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String) throw PegarouteCodecException('$key must be a string');
  return value;
}

String _requiredRequestId(String value, String key) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw PegarouteCodecException('$key must not be blank');
  return normalized;
}

String? _optionalRequestId(String? value, String key) {
  if (value == null) return null;
  return _requiredRequestId(value, key);
}

String? _normalizeRequestSender(String? sender) => _optionalRequestId(sender, 'senderAddress');

String? _normalizeRequestRefund(String chain, String? sender, String? refund) {
  final normalized = _optionalRequestId(refund, 'refundAddress');
  if (normalized == null || sender != null && _sameRequestAddress(chain, normalized, sender)) {
    return null;
  }
  return normalized;
}

bool _sameRequestAddress(String chain, String first, String second) {
  final normalizedChain = chain.trim().toUpperCase();
  const caseInsensitive = {'ETH', 'BSC', 'POLYGON', 'AVAX', 'ARBITRUM', 'BASE'};
  return caseInsensitive.contains(normalizedChain)
      ? first.toLowerCase() == second.toLowerCase()
      : first == second;
}

String _positiveAmount(String value) {
  final normalized = value.trim();
  final parsed = double.tryParse(normalized);
  if (!_isDecimal(normalized) || parsed == null || !parsed.isFinite || parsed <= 0) {
    throw const PegarouteCodecException('amount must be a finite positive decimal');
  }
  return normalized;
}

String? _optionalString(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) return null;
  final value = map[key];
  if (value is! String) throw PegarouteCodecException('$key must be a non-null string');
  return value;
}

String? _optionalNullableString(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) return null;
  final value = map[key];
  if (value == null) return null;
  if (value is! String) throw PegarouteCodecException('$key must be a string or null');
  return value;
}

String? _requiredNullableString(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) throw PegarouteCodecException('$key is required');
  return _optionalNullableString(map, key);
}

Object? _requiredNullableValue(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) throw PegarouteCodecException('$key is required');
  return map[key];
}

Object? _requiredNullableStringOrNum(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) throw PegarouteCodecException('$key is required');
  final value = map[key];
  if (value == null || value is String || value is num) return value;
  throw PegarouteCodecException('$key must be a string, number, or null');
}

PegarouteTokenAmount? _requiredNullableTokenAmount(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) throw PegarouteCodecException('$key is required');
  final value = map[key];
  return value == null ? null : PegarouteTokenAmount.fromJson(value);
}

PegarouteEvmApproval? _requiredNullableApproval(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) throw PegarouteCodecException('$key is required');
  final value = map[key];
  return value == null ? null : PegarouteEvmApproval.fromJson(value);
}

int _requiredInt(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! int) throw PegarouteCodecException('$key must be an integer');
  return value;
}

int? _optionalInt(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) return null;
  final value = map[key];
  if (value is! int) throw PegarouteCodecException('$key must be a non-null integer');
  return value;
}

Map<String, dynamic> _resolvedFee(Object? value) {
  final map = _object(value);
  if (map['feeBps'] is! num) throw const PegarouteCodecException('feeBps must be numeric');
  return map;
}

num? _optionalNum(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) return null;
  final value = map[key];
  if (value is! num) throw PegarouteCodecException('$key must be non-null numeric');
  return value;
}

num _requiredNum(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! num || !value.isFinite)
    throw PegarouteCodecException('$key must be finite numeric');
  return value;
}

bool _isDecimal(String value) => RegExp(r'^(0|[1-9][0-9]*)(\.[0-9]+)?$').hasMatch(value);

Never _invalid(String field) => throw PegarouteCodecException('invalid $field');

bool _validCalldata(String? value) {
  if (value == null || !value.startsWith('0x') || value.length <= 2) return false;
  final hex = value.substring(2);
  return hex.length.isEven && RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex);
}
