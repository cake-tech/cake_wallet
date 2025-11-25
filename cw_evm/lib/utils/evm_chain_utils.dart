import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/evm_chain_registry.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:web3dart/web3dart.dart' show EtherAmount, EtherUnit;

/// Utility class for chain-specific EVM chain operations
class EVMChainUtils {
  static int getTotalPriorityFee(
    EVMChainTransactionPriority priority,
    WalletType walletType, {
    int? chainId,
  }) {
    if (chainId == null && walletType == WalletType.evm) {
      throw Exception('chainId required for WalletType.evm');
    }

    if (chainId != null) {
      return getTotalPriorityFeeByChainId(priority, chainId);
    }

    return switch (walletType) {
      WalletType.ethereum => _ethereumPriorityFee(priority),
      WalletType.polygon => _polygonPriorityFee(priority),
      WalletType.base => _basePriorityFee(priority),
      WalletType.arbitrum => 0, // Arbitrum doesn't use priority fees
      _ => _ethereumPriorityFee(priority),
    };
  }

  static int getTotalPriorityFeeByChainId(EVMChainTransactionPriority priority, int chainId) {
    return switch (chainId) {
      1 => _ethereumPriorityFee(priority),
      137 => _polygonPriorityFee(priority),
      8453 => _basePriorityFee(priority),
      42161 => 0, // Arbitrum doesn't use priority fees
      _ => _ethereumPriorityFee(priority),
    };
  }

  /// Check if chain supports priority fees
  /// For WalletType.evm, chainId must be provided
  static bool hasPriorityFee(WalletType walletType, {int? chainId}) {
    if (chainId == null && walletType == WalletType.evm) {
      throw Exception('chainId required for WalletType.evm');
    }

    if (chainId != null) {
      return hasPriorityFeeByChainId(chainId);
    }

    return switch (walletType) {
      WalletType.arbitrum => false,
      _ => true,
    };
  }

  static bool hasPriorityFeeByChainId(int chainId) {
    return switch (chainId) {
      42161 => false, // Arbitrum doesn't use priority fees
      _ => true,
    };
  }

  static String getErc20TokensBoxName(String walletName, WalletType walletType, {int? chainId}) {
    final sanitizedName = walletName.replaceAll(" ", "_");

    if (chainId != null) {
      return getErc20TokensBoxNameByChainId(sanitizedName, chainId);
    }

    return switch (walletType) {
      WalletType.evm => throw Exception('chainId required for WalletType.evm'),
      WalletType.ethereum => "${sanitizedName}_${Erc20Token.ethereumBoxName}",
      WalletType.polygon => "${sanitizedName}_${Erc20Token.polygonBoxName}",
      WalletType.base => "${sanitizedName}_${Erc20Token.baseBoxName}",
      WalletType.arbitrum => "${sanitizedName}_${Erc20Token.arbitrumBoxName}",
      _ => "${sanitizedName}_${Erc20Token.ethereumBoxName}",
    };
  }

  static String getErc20TokensBoxNameByChainId(String sanitizedName, int chainId) {
    return switch (chainId) {
      1 => "${sanitizedName}_${Erc20Token.ethereumBoxName}",
      137 => "${sanitizedName}_${Erc20Token.polygonBoxName}",
      8453 => "${sanitizedName}_${Erc20Token.baseBoxName}",
      42161 => "${sanitizedName}_${Erc20Token.arbitrumBoxName}",
      _ => "${sanitizedName}_${Erc20Token.ethereumBoxName}",
    };
  }

  static String getTransactionHistoryFileNameByChainId(int chainId) {
    return switch (chainId) {
      1 => 'transactions.json', // Ethereum
      137 => 'polygon_transactions.json',
      8453 => 'base_transactions.json',
      42161 => 'arbitrum_transactions.json',
      _ => 'transactions_$chainId.json', // Generic format for other chains
    };
  }

  static String getTransactionHistoryFileName(WalletType walletType) {
    final registry = EvmChainRegistry();
    final chainId = registry.getChainIdByWalletType(walletType);
    if (chainId != null) {
      return getTransactionHistoryFileNameByChainId(chainId);
    }

    return 'transactions.json';
  }

  /// Get scan provider preference key for a wallet type
  static String getScanProviderPreferenceKey(WalletType walletType) {
    return switch (walletType) {
      WalletType.ethereum => 'use_etherscan',
      WalletType.polygon => 'use_polygonscan',
      WalletType.base => 'use_basescan',
      WalletType.arbitrum => 'use_arbiscan',
      _ => 'use_etherscan',
    };
  }

  static String getDefaultTokenTag(WalletType walletType) {
    return switch (walletType) {
      WalletType.ethereum => 'ETH',
      WalletType.polygon => 'POL',
      WalletType.base => 'ETH',
      WalletType.arbitrum => 'ETH',
      _ => 'ETH',
    };
  }

  static String getFeeCurrency(WalletType walletType) {
    return switch (walletType) {
      WalletType.ethereum => 'ETH',
      WalletType.polygon => 'MATIC',
      WalletType.base => 'ETH',
      WalletType.arbitrum => 'ETH',
      _ => 'ETH',
    };
  }

  static String getDefaultTokenSymbol(WalletType walletType) {
    return switch (walletType) {
      WalletType.ethereum => 'ETH',
      WalletType.polygon => 'MATIC',
      WalletType.base => 'ETH',
      WalletType.arbitrum => 'ETH',
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
