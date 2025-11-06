import 'package:cake_wallet/src/screens/wallet_connect/utils/string_parsing.dart';

class EVMTransactionErrorFeesHandler {
  EVMTransactionErrorFeesHandler({
    this.balanceWei,
    this.balanceEth,
    this.balanceUsd,
    this.txCostWei,
    this.txCostEth,
    this.txCostUsd,
    this.overshotWei,
    this.overshotEth,
    this.overshotUsd,
    this.error,
  });

  String? balanceWei;
  String? balanceEth;
  String? balanceUsd;

  String? txCostWei;
  String? txCostEth;
  String? txCostUsd;

  String? overshotWei;
  String? overshotEth;
  String? overshotUsd;

  String? error;

  factory EVMTransactionErrorFeesHandler.parseEthereumFeesErrorMessage(
    String errorMessage,
    double assetPriceUsd,
  ) {
    // Allows us define multiple patterns to parse the error message
    // Order matters: more specific patterns first, generic patterns last
    final patterns = [
      // Pattern 1: "have X want Y" format
      ErrorPattern(
        name: 'have_want',
        regex: RegExp(r'have\s+(\d+)\s+want\s+(\d+)', caseSensitive: false),
        extractor: (match) => {
          'balance': match.group(1)!,
          'required': match.group(2)!,
        },
        calculator: (values) => {
          'balanceWei': values['balance']!,
          'txCostWei': values['required']!,
          'overshotWei':
              (BigInt.parse(values['required']!) - BigInt.parse(values['balance']!)).toString(),
        },
      ),

      // Pattern 2: "balance X, queued cost Y, tx cost Z, overshot W" format (most specific)
      ErrorPattern(
        name: 'balance_queued_txcost_overshot',
        regex: RegExp(r'balance\s+(\d+),\s*queued\s+cost\s+(\d+),\s*tx\s+cost\s+(\d+),\s*overshot\s+(\d+)', caseSensitive: false),
        extractor: (match) => {
          'balance': match.group(1)!,
          'txCost': match.group(3)!, // Skip queued cost, use tx cost
          'overshot': match.group(4)!,
        },
        calculator: (values) => {
          'balanceWei': values['balance']!,
          'txCostWei': values['txCost']!,
          'overshotWei': values['overshot']!,
        },
      ),

      // Pattern 3: "balance X, tx cost Y, overshot Z" format
      ErrorPattern(
        name: 'balance_txcost_overshot',
        regex: RegExp(r'balance\s+(\d+),\s*tx\s+cost\s+(\d+),\s*overshot\s+(\d+)', caseSensitive: false),
        extractor: (match) => {
          'balance': match.group(1)!,
          'txCost': match.group(2)!,
          'overshot': match.group(3)!,
        },
        calculator: (values) => {
          'balanceWei': values['balance']!,
          'txCostWei': values['txCost']!,
          'overshotWei': values['overshot']!,
        },
      ),

      // Pattern 4: Individual field matching (legacy fallback)
      ErrorPattern(
        name: 'individual_fields',
        regex: RegExp(r'balance\s+(\d+).*tx\s+cost\s+(\d+).*overshot\s+(\d+)', caseSensitive: false),
        extractor: (match) => {
          'balance': match.group(1)!,
          'txCost': match.group(2)!,
          'overshot': match.group(3)!,
        },
        calculator: (values) => {
          'balanceWei': values['balance']!,
          'txCostWei': values['txCost']!,
          'overshotWei': values['overshot']!,
        },
      ),

      // Pattern 5: Generic "insufficient funds for gas * price + value" (least specific - must be last)
      ErrorPattern(
        name: 'generic_insufficient_funds',
        regex: RegExp(r'insufficient\s+funds\s+for\s+gas\s*\*\s*price\s*\+\s*value', caseSensitive: false),
        extractor: (match) => {
          'balance': '0', // We don't have specific values, so use 0
          'txCost': '0',
          'overshot': '0',
        },
        calculator: (values) => {
          'balanceWei': values['balance']!,
          'txCostWei': values['txCost']!,
          'overshotWei': values['overshot']!,
        },
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.regex.firstMatch(errorMessage);
      if (match != null) {
        try {
          final extractedValues = pattern.extractor(match);
          final calculatedValues = pattern.calculator(extractedValues);

          return _createHandlerFromValues(calculatedValues, assetPriceUsd);
        } catch (e) {
          continue;
        }
      }
    }

    return EVMTransactionErrorFeesHandler(error: 'Could not parse the error message.');
  }

  /// Creates a handler instance from parsed values
  static EVMTransactionErrorFeesHandler _createHandlerFromValues(
    Map<String, String> values,
    double assetPriceUsd,
  ) {
    final balanceWei = BigInt.parse(values['balanceWei']!);
    final txCostWei = BigInt.parse(values['txCostWei']!);
    final overshotWei = BigInt.parse(values['overshotWei']!);

    final isGenericError = balanceWei == BigInt.zero && 
                          txCostWei == BigInt.zero && 
                          overshotWei == BigInt.zero;

    if (isGenericError) {
      return genericInsufficientFunds();
    }

    // Convert wei to ETH (1 ETH = 1e18 wei)
    final balanceEth = balanceWei.toDouble() / 1e18;
    final txCostEth = txCostWei.toDouble() / 1e18;
    final overshotEth = overshotWei.toDouble() / 1e18;

    // Calculate USD values
    final balanceUsd = balanceEth * assetPriceUsd;
    final txCostUsd = txCostEth * assetPriceUsd;
    final overshotUsd = overshotEth * assetPriceUsd;

    return EVMTransactionErrorFeesHandler(
      balanceWei: balanceWei.toString(),
      balanceEth: balanceEth.toString().safeSubString(0, 12),
      balanceUsd: balanceUsd.toString().safeSubString(0, 4),
      txCostWei: txCostWei.toString(),
      txCostEth: txCostEth.toString().safeSubString(0, 12),
      txCostUsd: txCostUsd.toString().safeSubString(0, 4),
      overshotWei: overshotWei.toString(),
      overshotEth: overshotEth.toString().safeSubString(0, 12),
      overshotUsd: overshotUsd.toString().safeSubString(0, 4),
    );
  }

  static EVMTransactionErrorFeesHandler genericInsufficientFunds() {
    return EVMTransactionErrorFeesHandler(
      balanceWei: '0',
      balanceEth: '0',
      balanceUsd: '0',
      txCostWei: '0',
      txCostEth: '0',
      txCostUsd: '0',
      overshotWei: '0',
      overshotEth: '0',
      overshotUsd: '0',
      error: 'generic_insufficient_funds',
    );
  }
}

/// Represents an error parsing pattern
class ErrorPattern {
  final String name;
  final RegExp regex;
  final Map<String, String> Function(Match) extractor;
  final Map<String, String> Function(Map<String, String>) calculator;

  ErrorPattern({
    required this.name,
    required this.regex,
    required this.extractor,
    required this.calculator,
  });
}
