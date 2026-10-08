import "package:cw_core/crypto_currency.dart";
import "package:cw_evm/evm_chain_exceptions.dart";
import "package:cw_evm/evm_chain_registry.dart";
import "package:cw_evm/evm_chain_transaction_priority.dart";
import "package:web3dart/web3dart.dart" show EtherAmount, EtherUnit;

/// Utility class for chain-specific EVM chain operations
class EVMChainUtils {
  static int? getTotalPriorityFee(EVMChainTransactionPriority priority, int chainId) => switch (chainId) {
      1 => _ethereumPriorityFee(priority),
      137 => _polygonPriorityFee(priority),
      8453 => _basePriorityFee(priority),
      56 => _ethereumPriorityFee(priority),
      42161 => 0, // Arbitrum doesn't use priority fees
      4663 => 0, // Robinhood Chain (Arbitrum Orbit) doesn't use priority fees
      _ => null,
    };

  static bool hasPriorityFee(int chainId) => switch (chainId) {
        42161 => false, // Arbitrum doesn't use priority fees
        4663 => false, // Robinhood Chain (Arbitrum Orbit) doesn't use priority fees
        _ => true,
      };

  static int computeBufferedMaxFeePerGasWei({
    required int? gasBaseFee,
    required int gasPrice,
    required int priorityFeeWei,
    required bool chainHasPriorityFee,
  }) {
    final priorityFee = BigInt.from(priorityFeeWei);
    if (gasBaseFee != null && gasBaseFee > 0) {
      final baseFeeWithPriority = BigInt.from(gasBaseFee) + priorityFee;
      final bufferMultiplier = BigInt.from(chainHasPriorityFee ? 115 : 105);
      final bufferPercent = (baseFeeWithPriority * bufferMultiplier) ~/ BigInt.from(100);
      final bufferMin = baseFeeWithPriority + (baseFeeWithPriority ~/ BigInt.from(100));
      return weiAsInt(bufferPercent > bufferMin ? bufferPercent : bufferMin);
    }
    return weiAsInt(BigInt.from(gasPrice) + priorityFee);
  }

  static int weiAsInt(BigInt wei) {
    if (wei.isNegative || !wei.isValidInt) {
      throw EVMChainTransactionFeesException("Fee out of range: $wei wei");
    }

    return wei.toInt();
  }

  static String hexChainId(int chainId) => "0x${chainId.toRadixString(16)}";

  static String getTransactionHistoryFileName(int chainId) => switch (chainId) {
        1 => "transactions.json", // Ethereum
        137 => "polygon_transactions.json",
        8453 => "base_transactions.json",
        42161 => "arbitrum_transactions.json",
        56 => "bsc_transactions.json",
        4663 => "robinhood_transactions.json",
        _ => "transactions_$chainId.json", // Generic format for other chains
      };

  /// Get scan provider preference key for a wallet type
  static String getScanProviderPreferenceKey(int chainId) => switch (chainId) {
      1 => "use_etherscan",
      137 => "use_polygonscan",
      8453 => "use_base_scan",
      42161 => "use_arbitrum_scan",
      56 => "use_bscscan",
      4663 => "use_robinhood_scan",
      _ => "use_evm_scan_$chainId",
    };

  static String getDefaultTokenTag(int chainId) {
    final nativeCurrency = _getNativeCurrency(chainId);
    return nativeCurrency.tag ?? nativeCurrency.title;
  }

  static String getFeeCurrency(int chainId) => _getNativeCurrency(chainId).title;

  static CryptoCurrency _getNativeCurrency(int chainId) {
    final config = EvmChainRegistry().getChainConfig(chainId);
    if (config == null) {
      throw Exception("No EVM network registered for chain ID $chainId");
    }

    return config.nativeCurrency;
  }

  static int _ethereumPriorityFee(EVMChainTransactionPriority priority) =>
      EtherAmount.fromInt(EtherUnit.gwei, priority.tip).getInWei.toInt();

  // Polygon priority fee calculation (minimum 25 gwei + additional based on priority)
  static int _polygonPriorityFee(EVMChainTransactionPriority priority) {
    const int minPriorityFee = 25;
    final minPriorityFeeWei = EtherAmount.fromInt(EtherUnit.gwei, minPriorityFee).getInWei.toInt();

    final int additionalPriorityFee = switch (priority) {
      EVMChainTransactionPriority.slow => 0,
      EVMChainTransactionPriority.medium =>
        EtherAmount.fromInt(EtherUnit.gwei, 15).getInWei.toInt(),
      EVMChainTransactionPriority.fast => EtherAmount.fromInt(EtherUnit.gwei, 35).getInWei.toInt(),
      _ => 0,
    };

    return minPriorityFeeWei + additionalPriorityFee;
  }

  static int _basePriorityFee(EVMChainTransactionPriority priority) => switch (priority) {
        EVMChainTransactionPriority.fast => EtherAmount.fromInt(EtherUnit.mwei, 5).getInWei.toInt(),
        EVMChainTransactionPriority.medium =>
          EtherAmount.fromInt(EtherUnit.mwei, 3).getInWei.toInt(),
        EVMChainTransactionPriority.slow => EtherAmount.fromInt(EtherUnit.mwei, 1).getInWei.toInt(),
        _ => EtherAmount.fromInt(EtherUnit.mwei, 1).getInWei.toInt(),
      };
}
