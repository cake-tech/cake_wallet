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
    // Define Regular Expressions to extract the numerical values
    RegExp balanceRegExp = RegExp(r'balance (\d+)');
    RegExp txCostRegExp = RegExp(r'tx cost (\d+)');
    RegExp overshotRegExp = RegExp(r'overshot (\d+)');

    // Match the patterns in the error message
    Match? balanceMatch = balanceRegExp.firstMatch(errorMessage);
    Match? txCostMatch = txCostRegExp.firstMatch(errorMessage);
    Match? overshotMatch = overshotRegExp.firstMatch(errorMessage);

    // Check if all required values are found
    if (balanceMatch != null && txCostMatch != null && overshotMatch != null) {
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
        balanceEth: balanceEth.toString().substring(0, 12),
        balanceUsd: balanceUsd.toString().substring(0, 4),
        txCostWei: txCostWei.toString(),
        txCostEth: txCostEth.toString().substring(0, 12),
        txCostUsd: txCostUsd.toString().substring(0, 4),
        overshotWei: overshotWei.toString(),
        overshotEth: overshotEth.toString().substring(0, 12),
        overshotUsd: overshotUsd.toString().substring(0, 4),
      );
    } else {
      // If any value is missing, return an error message
      return EVMTransactionErrorFeesHandler(error: 'Could not parse the error message.');
    }
  }
}
