import 'package:cw_core/crypto_currency.dart';

/// Immutable configuration for an EVM chain
class ChainConfig {
  final int chainId;
  final String name;
  final String shortCode;
  final String caip2; // e.g., "eip155:1"
  final CryptoCurrency nativeCurrency;
  final ChainCapabilities capabilities;
  final List<String> defaultRpcEndpoints;
  final List<String> explorerUrls;
  final FeeModel feeModel;

  const ChainConfig({
    required this.chainId,
    required this.name,
    required this.shortCode,
    required this.caip2,
    required this.nativeCurrency,
    required this.capabilities,
    required this.defaultRpcEndpoints,
    required this.explorerUrls,
    required this.feeModel,
  });
}

/// Capabilities supported by an EVM chain
class ChainCapabilities {
  final bool supportsERC20;
  final bool supportsEIP1559;
  final bool supportsInternalTx;
  final bool supportsSubscriptions;
  final bool supportsENS;

  const ChainCapabilities({
    required this.supportsERC20,
    required this.supportsEIP1559,
    required this.supportsInternalTx,
    required this.supportsSubscriptions,
    required this.supportsENS,
  });
}

/// Fee model type for EVM chains
enum FeeType {
  legacy,
  eip1559,
}

/// Fee model configuration for an EVM chain
class FeeModel {
  final FeeType type;
  final int defaultGasLimit;
  final int? maxPriorityFee;

  const FeeModel({
    required this.type,
    required this.defaultGasLimit,
    this.maxPriorityFee,
  });
}

