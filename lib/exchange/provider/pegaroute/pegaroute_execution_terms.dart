import 'package:collection/collection.dart';
import 'pegaroute_api.dart';
import 'pegaroute_amount.dart';

/// Wire-term checks reused from the final integration without its generic
/// execution envelope, wallet binding model or persistence lifecycle.
class PegarouteExecutionTerms {
  static String _canonicalChain(String chain) => chain.trim().toUpperCase();

  static void validateProviderDetails({
    required PegarouteProviderInfo provider,
    required Map<String, dynamic> route,
    required PegarouteExecution execution,
    required String sourceChain,
    required String sourceAmount,
  }) {
    if (_trustedSolanaSerialized(route, execution)) return;
    final details = provider.instaswapSwapLite;
    if (details != null) {
      if (provider.referenceId == null || details.txid != provider.referenceId) {
        throw const PegarouteCodecException('provider reference details changed');
      }
      if (details.depositAmountExact != null &&
          !pegarouteSameAmount(details.depositAmountExact!, sourceAmount)) {
        throw const PegarouteCodecException('provider deposit amount changed');
      }
      if (execution.to == null ||
          !sameAddress(sourceChain, execution.to!, details.depositAddress)) {
        throw const PegarouteCodecException('provider deposit target changed');
      }
      if (details.expiresAt != null && DateTime.tryParse(details.expiresAt!) == null) {
        throw const PegarouteCodecException('provider deposit expiry is invalid');
      }
      final inbound = route['inboundAddress'];
      if (inbound is String &&
          inbound.isNotEmpty &&
          !sameAddress(sourceChain, inbound, details.depositAddress)) {
        throw const PegarouteCodecException('provider deposit address changed');
      }
    }
    validateReviewedExecution(route: route, execution: execution, sourceChain: sourceChain,
        providerDepositAddress: details?.depositAddress);
  }

  /// Check reviewed targets, memos and spenders at creation and each store read.
  /// API-only deposit details are checked by validateProviderDetails above.
  static void validateReviewedExecution({
    required Map<String, dynamic> route,
    required PegarouteExecution execution,
    required String sourceChain,
    String? providerDepositAddress,
  }) {
    if (_trustedSolanaSerialized(route, execution)) return;
    final expectedTarget = _expectedTarget(
      route,
      execution,
      providerDepositAddress: providerDepositAddress,
    );
    if (expectedTarget == null ||
        execution.to == null ||
        !sameAddress(sourceChain, execution.to!, expectedTarget)) {
      throw const PegarouteCodecException('execution destination is not reviewed');
    }
    final routeMemo = route['memo'];
    if ((routeMemo != null && routeMemo is! String) || execution.memo != routeMemo) {
      throw const PegarouteCodecException('execution memo is not reviewed');
    }
    if (execution.approval != null) {
      final router = route['router'];
      if (!(route['provider'] == 'openocean' && router == null) &&
          (router is! String || !sameAddress(sourceChain, execution.approval!.spender, router))) {
        throw const PegarouteCodecException('approval spender is not reviewed');
      }
    }
  }

  static String? _expectedTarget(Map<String, dynamic> route, PegarouteExecution execution,
      {String? providerDepositAddress}) {
    final router = route['router'];
    final inbound = route['inboundAddress'];
    final providerDeposit = providerDepositAddress;
    if (execution.family == 'evm' &&
        execution.mode == 'contract-call' &&
        router is String &&
        router.isNotEmpty) return router;
    if (inbound is String && inbound.isNotEmpty) return inbound;
    if (providerDeposit != null && providerDeposit.isNotEmpty) return providerDeposit;
    if (router is String && router.isNotEmpty) return router;
    // OpenOcean supplies its concrete target at creation. Under the approved
    // trusted-provider model, bind that authenticated target with its calldata.
    if (route['provider'] == 'openocean' && execution.family == 'evm') return execution.to;
    // Instaswap may allocate its deposit only at creation. Provider details
    // are optional; the authenticated transfer is sufficient when no earlier
    // target was supplied. Details, when present, are still cross-checked.
    if (route['provider'] == 'instaswap' &&
        const {'native-transfer', 'erc20-transfer', 'payment-with-memo', 'deposit-transfer'}
            .contains(execution.mode)) return execution.to;
    return null;
  }

  static bool _trustedSolanaSerialized(Map<String, dynamic> route, PegarouteExecution execution) =>
      route['provider'] == 'openocean' &&
      execution.family == 'solana' &&
      execution.mode == 'serialized-tx';

  static void validateExecution({
    required PegarouteExecution execution,
    required String sourceChain,
    required String sourceToken,
    required String nativeToken,
    required int? walletChainId,
    required String sourceAmount,
    required int sourceDecimals,
  }) {
    final expectedFamily = familyForChain(sourceChain);
    if (expectedFamily != null && execution.family != expectedFamily) {
      throw const PegarouteCodecException('execution family does not match source chain');
    }
    final expectedBaseUnits = toBaseUnits(sourceAmount, sourceDecimals);
    final chainId = chainIdFor(sourceChain);
    if (execution.family == 'evm') {
      if (execution.chainId != chainId || walletChainId != chainId) {
        throw const PegarouteCodecException('execution EVM chain is not bound');
      }
      if (execution.mode == 'native-transfer') {
        _requireAmount(execution.value, sourceAmount, expectedBaseUnits);
      } else if (execution.mode == 'erc20-transfer') {
        _requireAmount(execution.transferAmount, sourceAmount, expectedBaseUnits);
      } else if (execution.mode == 'contract-call') {
        if (sourceToken == nativeToken) {
          _requireAmount(execution.value, sourceAmount, expectedBaseUnits);
        } else {
          if (execution.value != null &&
              (!pegarouteSameAmount(execution.value!.display, '0') ||
                  execution.value!.baseUnits != '0')) {
            throw const PegarouteCodecException('native call value is not bound');
          }
          // Authenticated source identity/amount and exact calldata are bound;
          // token debit/output effects are trusted to the provider.
          if (_tokenIdentity(sourceToken) == null) {
            throw const PegarouteCodecException('token call identity is missing');
          }
        }
        if (execution.approval != null) {
          final identity = _tokenIdentity(sourceToken);
          if (identity == null ||
              !sameAddress(sourceChain, identity, execution.approval!.tokenAddress)) {
            throw const PegarouteCodecException('approval token is not bound');
          }
          _requireAmount(execution.approval!.amount, sourceAmount, expectedBaseUnits);
        }
      }
      return;
    }
    if (execution.mode == 'serialized-tx') {
      if (sourceChain == 'SOL' && execution.family == 'solana') return;
      throw const PegarouteCodecException('opaque serialized execution is unavailable');
    }
    if (execution.family == 'other' && execution.chain != sourceChain) {
      throw const PegarouteCodecException('opaque execution chain changed');
    }
    _requireAmount(execution.amount, sourceAmount, expectedBaseUnits);
  }

  static void _requireAmount(PegarouteTokenAmount? amount, String display, String baseUnits) {
    if (amount == null ||
        !pegarouteSameAmount(amount.display, display) ||
        amount.baseUnits != baseUnits) {
      throw const PegarouteCodecException('execution amount differs from requested amount');
    }
  }

  static String? _tokenIdentity(String token) {
    final separator = token.indexOf('-');
    return separator < 0 ? null : token.substring(separator + 1);
  }

  static int? chainIdFor(String chain) {
    return const {
      'ETH': 1,
      'BSC': 56,
      'POLYGON': 137,
      'AVAX': 43114,
      'ARBITRUM': 42161,
      'BASE': 8453,
    }[_canonicalChain(chain)];
  }

  static String? familyForChain(String chain) {
    final normalized = _canonicalChain(chain);
    if (chainIdFor(normalized) != null) return 'evm';
    return switch (normalized) {
      'BTC' || 'BCH' || 'LTC' || 'DOGE' || 'DASH' || 'ZEC' => 'utxo',
      'SOL' => 'solana',
      'SUI' => 'sui',
      'XRP' => 'xrp',
      'TRON' => 'tron',
      'NEAR' => 'near',
      'CARDANO' => 'cardano',
      'THOR' => 'cosmos',
      'XMR' || 'STELLAR' => 'other',
      _ => null,
    };
  }

  static String toBaseUnits(String amount, int decimals) {
    final normalized = amount.trim();
    final match = RegExp(r'^(0|[1-9][0-9]*)(\.[0-9]+)?$').firstMatch(normalized);
    if (match == null) throw const PegarouteCodecException('amount is not canonical');
    final fraction = match.group(2)?.substring(1) ?? '';
    if (fraction.length > decimals) {
      throw const PegarouteCodecException('amount has excess precision');
    }
    final whole = match.group(1)!;
    return (BigInt.parse(whole) * BigInt.from(10).pow(decimals) +
            BigInt.parse(
                fraction.padRight(decimals, '0').isEmpty ? '0' : fraction.padRight(decimals, '0')))
        .toString();
  }

  static bool sameAddress(String chain, String first, String second) {
    final a = first.trim();
    final b = second.trim();
    if (a.isEmpty || b.isEmpty) return false;
    final folded = const {
      'ETH',
      'BSC',
      'POLYGON',
      'AVAX',
      'ARBITRUM',
      'BASE',
    };
    return folded.contains(chain.toUpperCase()) ? a.toLowerCase() == b.toLowerCase() : a == b;
  }

  static bool sameRouteEcho(
      Map<String, dynamic> expected, PegarouteRoute actual, String? providerType,
      [bool requireIdentityFields = false]) {
    final echoed = routeSnapshot(actual, providerType: providerType);
    const requiredIdentityFields = {
      'provider',
      'expectedOutput',
      'fees',
      'estimatedTimeSeconds',
    };
    if (requireIdentityFields && !actual.presentFields.containsAll(requiredIdentityFields)) {
      return false;
    }
    final keys = <String>[
      'provider',
      'private',
      'expectedOutput',
      'fees',
      'estimatedTimeSeconds',
    ];
    if (providerType != null) keys.add('providerType');
    for (final key in keys) {
      // Omitted private is public. Optional subprovider/DEX labels can be
      // enriched at creation or polling without changing the funding intent.
      if (key != 'providerType' && key != 'private' && !actual.presentFields.contains(key))
        continue;
      if (key == 'expectedOutput') {
        if (!pegarouteSameAmount(expected[key] as String, actual.expectedOutput)) return false;
      } else if (!const DeepCollectionEquality().equals(expected[key], echoed[key])) {
        return false;
      }
    }
    return true;
  }

  static Map<String, dynamic> routeSnapshot(PegarouteRoute route, {String? providerType}) => {
        'provider': route.provider,
        'providerType': providerType ?? route.providerType,
        'subprovider': route.subprovider,
        'private': route.privateValue?.value ?? false,
        'expectedOutput': route.expectedOutput,
        'fees': _feesSnapshot(route.fees),
        'estimatedTimeSeconds': route.estimatedTimeSeconds,
        'memo': route.memo,
        'inboundAddress': route.inboundAddress,
        'router': route.router,
        'minAmount': route.minAmount,
        'expiry': route.expiry == null
            ? null
            : pegarouteRouteDeadline(route.expiry)!.toIso8601String(),
        'gasRate': route.gasRate,
        'resolvedFee': route.resolvedFee,
        'openOceanRoute': route.openOceanRoute == null
            ? null
            : {
                'dexId': route.openOceanRoute!.dexId,
                'dexCode': route.openOceanRoute!.dexCode,
                'dexes': route.openOceanRoute!.dexes
                    ?.map((dex) => {'dexId': dex.dexId, 'dexCode': dex.dexCode})
                    .toList(),
              },
      };

  static Map<String, dynamic>? _feesSnapshot(PegarouteFees? fees) => fees == null
      ? null
      : {
          'affiliate': fees.affiliate,
          'liquidity': fees.liquidity,
          'outbound': fees.outbound,
          'subAffiliate': fees.subAffiliate,
          'total': fees.total,
          'totalBps': fees.totalBps,
          'slippageBps': fees.slippageBps,
        };

}
