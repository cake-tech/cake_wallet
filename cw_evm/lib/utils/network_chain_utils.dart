import 'package:cw_core/crypto_currency.dart';

/// Immutable configuration for an EVM chain
class ChainConfig {
  final int chainId;
  final String name;
  final String shortCode;
  final String caip2; // e.g., "eip155:1"
  final CryptoCurrency nativeCurrency;
  final List<String> explorerUrls;
  final FeeModel feeModel;

  const ChainConfig({
    required this.chainId,
    required this.name,
    required this.shortCode,
    required this.caip2,
    required this.nativeCurrency,
    required this.explorerUrls,
    required this.feeModel,
  });
}

/// Fee model type for EVM chains
enum FeeType {
  legacy,
  eip1559,
  eip1559OrLegacy,
}

/// Fee model configuration for an EVM chain
class FeeModel {
  final FeeType type;

  const FeeModel({required this.type});
}
