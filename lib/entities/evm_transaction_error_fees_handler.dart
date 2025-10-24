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
    // Pattern 1: "insufficient funds for gas * price + value: have 4728796358953246 want 4728796842182575"
    RegExp insufficientFundsRegExp = RegExp(r'have (\d+) want (\d+)');
    Match? insufficientFundsMatch = insufficientFundsRegExp.firstMatch(errorMessage);

    if (insufficientFundsMatch != null) {
      try {
        // Extract the numerical strings from the new format
        String balanceStr = insufficientFundsMatch.group(1)!;
        String requiredStr = insufficientFundsMatch.group(2)!;

        // Parse the numerical strings to BigInt
        BigInt balanceWei = BigInt.parse(balanceStr);
        BigInt requiredWei = BigInt.parse(requiredStr);

        // Calculate overshot (how much more is needed)
        BigInt overshotWei = requiredWei - balanceWei;

        // The transaction cost is the required amount
        BigInt txCostWei = requiredWei;

        // Convert wei to ETH (1 ETH = 1e18 wei)
        double balanceEth = balanceWei.toDouble() / 1e18;
        double txCostEth = txCostWei.toDouble() / 1e18;
        double overshotEth = overshotWei.toDouble() / 1e18;

        // Calculate the USD values
        double balanceUsd = balanceEth * assetPriceUsd;
        double txCostUsd = txCostEth * assetPriceUsd;
        double overshotUsd = overshotEth * assetPriceUsd;

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
      } catch (e) {}
    }

    // Pattern 2: "insufficient funds for gas * price + value: balance 0, tx cost 733549007678518, overshot 733549007678518"
    RegExp balanceTxCostOvershotRegExp = RegExp(r'balance (\d+), tx cost (\d+), overshot (\d+)');
    Match? balanceTxCostOvershotMatch = balanceTxCostOvershotRegExp.firstMatch(errorMessage);

    if (balanceTxCostOvershotMatch != null) {
      try {
        // Extract the numerical strings
        String balanceStr = balanceTxCostOvershotMatch.group(1)!;
        String txCostStr = balanceTxCostOvershotMatch.group(2)!;
        String overshotStr = balanceTxCostOvershotMatch.group(3)!;

        // Parse the numerical strings to BigInt
        BigInt balanceWei = BigInt.parse(balanceStr);
        BigInt txCostWei = BigInt.parse(txCostStr);
        BigInt overshotWei = BigInt.parse(overshotStr);

        // Convert wei to ETH (1 ETH = 1e18 wei)
        double balanceEth = balanceWei.toDouble() / 1e18;
        double txCostEth = txCostWei.toDouble() / 1e18;
        double overshotEth = overshotWei.toDouble() / 1e18;

        // Calculate the USD values
        double balanceUsd = balanceEth * assetPriceUsd;
        double txCostUsd = txCostEth * assetPriceUsd;
        double overshotUsd = overshotEth * assetPriceUsd;

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
      } catch (e) {}
    }

    // Pattern 3: Legacy format "balance (\d+) tx cost (\d+) overshot (\d+)"
    RegExp balanceRegExp = RegExp(r'balance (\d+)');
    RegExp txCostRegExp = RegExp(r'tx cost (\d+)');
    RegExp overshotRegExp = RegExp(r'overshot (\d+)');

    // Match the patterns in the error message
    Match? balanceMatch = balanceRegExp.firstMatch(errorMessage);
    Match? txCostMatch = txCostRegExp.firstMatch(errorMessage);
    Match? overshotMatch = overshotRegExp.firstMatch(errorMessage);

    // Check if all required values are found
    if (balanceMatch != null && txCostMatch != null && overshotMatch != null) {
      try {
        // Extract the numerical strings
        String balanceStr = balanceMatch.group(1)!;
        String txCostStr = txCostMatch.group(1)!;
        String overshotStr = overshotMatch.group(1)!;

        // Parse the numerical strings to BigInt
        BigInt balanceWei = BigInt.parse(balanceStr);
        BigInt txCostWei = BigInt.parse(txCostStr);
        BigInt overshotWei = BigInt.parse(overshotStr);

        // Convert wei to ETH (1 ETH = 1e18 wei)
        double balanceEth = balanceWei.toDouble() / 1e18;
        double txCostEth = txCostWei.toDouble() / 1e18;
        double overshotEth = overshotWei.toDouble() / 1e18;

        // Calculate the USD values
        double balanceUsd = balanceEth * assetPriceUsd;
        double txCostUsd = txCostEth * assetPriceUsd;
        double overshotUsd = overshotEth * assetPriceUsd;

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
      } catch (e) {
        // If parsing fails, continue to error case
      }
    }

    // If all parsing attempts fail, return an error message
    return EVMTransactionErrorFeesHandler(error: 'Could not parse the error message.');
  }
}
