import 'package:cw_core/erc20_token.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:web3dart/web3dart.dart' show EtherAmount, EtherUnit;

/// Utility class for chain-specific EVM chain operations
class EVMChainUtils {
  static int getTotalPriorityFee(EVMChainTransactionPriority priority, int chainId) {
    return switch (chainId) {
      1 => _ethereumPriorityFee(priority),
      137 => _polygonPriorityFee(priority),
      8453 => _basePriorityFee(priority),
      42161 => 0, // Arbitrum doesn't use priority fees
      _ => _ethereumPriorityFee(priority),
    };
  }

  static bool hasPriorityFee(int chainId) {
    return switch (chainId) {
      42161 => false, // Arbitrum doesn't use priority fees
      _ => true,
    };
  }

  static String getErc20TokensBoxName(String walletName, int chainId) {
    final sanitizedName = walletName.replaceAll(" ", "_");

    return switch (chainId) {
      1 => "${sanitizedName}_${Erc20Token.ethereumBoxName}",
      137 => "${sanitizedName}_${Erc20Token.polygonBoxName}",
      8453 => "${sanitizedName}_${Erc20Token.baseBoxName}",
      42161 => "${sanitizedName}_${Erc20Token.arbitrumBoxName}",
      _ => "${sanitizedName}_${Erc20Token.ethereumBoxName}",
    };
  }

  static String getTransactionHistoryFileName(int chainId) {
    return switch (chainId) {
      1 => 'transactions.json', // Ethereum
      137 => 'polygon_transactions.json',
      8453 => 'base_transactions.json',
      42161 => 'arbitrum_transactions.json',
      _ => 'transactions_$chainId.json', // Generic format for other chains
    };
  }

  /// Get scan provider preference key for a wallet type
  static String getScanProviderPreferenceKey(int chainId) {
    return switch (chainId) {
      1 => 'use_etherscan',
      137 => 'use_polygonscan',
      8453 => 'use_basescan',
      42161 => 'use_arbiscan',
      _ => 'use_etherscan',
    };
  }

  static String getDefaultTokenTag(int chainId) {
    return switch (chainId) {
      1 => 'ETH',
      137 => 'POL',
      8453 => 'ETH',
      42161 => 'ETH',
      _ => 'ETH',
    };
  }

  static String getFeeCurrency(int chainId) {
    return switch (chainId) {
      1 => 'ETH',
      137 => 'MATIC',
      8453 => 'ETH',
      42161 => 'ETH',
      _ => 'ETH',
    };
  }

  static String getDefaultTokenSymbol(int chainId) {
    return switch (chainId) {
      1 => 'ETH',
      137 => 'MATIC',
      8453 => 'ETH',
      42161 => 'ETH',
      _ => 'ETH',
    };
  }

  static int _ethereumPriorityFee(EVMChainTransactionPriority priority) {
    return EtherAmount.fromInt(EtherUnit.gwei, priority.tip).getInWei.toInt();
  }

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

  static int _basePriorityFee(EVMChainTransactionPriority priority) {
    return switch (priority) {
      EVMChainTransactionPriority.fast => EtherAmount.fromInt(EtherUnit.mwei, 5).getInWei.toInt(),
      EVMChainTransactionPriority.medium => EtherAmount.fromInt(EtherUnit.mwei, 3).getInWei.toInt(),
      EVMChainTransactionPriority.slow => EtherAmount.fromInt(EtherUnit.mwei, 1).getInWei.toInt(),
      _ => EtherAmount.fromInt(EtherUnit.mwei, 1).getInWei.toInt(),
    };
  }
}
