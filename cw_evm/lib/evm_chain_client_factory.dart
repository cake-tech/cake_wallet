import 'package:cw_evm/clients/arbitrum_client.dart';
import 'package:cw_evm/clients/base_client.dart';
import 'package:cw_evm/clients/ethereum_client.dart';
import 'package:cw_evm/clients/polygon_client.dart';
import 'package:cw_evm/clients/evm_chain_client.dart';
import 'package:cw_evm/evm_chain_registry.dart';

/// Factory to create appropriate EVMChainClient based on chainId
class EVMChainClientFactory {
  static final EvmChainRegistry _registry = EvmChainRegistry();

  /// Create an EVMChainClient for the given chainId
  ///
  /// Throws an exception if chainId is not registered
  static EVMChainClient createClient(int chainId) {
    final config = _registry.getChainConfig(chainId);

    if (config == null) {
      throw Exception('Chain config not found for chainId: $chainId');
    }

    // Check if chain needs custom client
    switch (chainId) {
      case 1:
        return EthereumClient();
      case 137:
        return PolygonClient();
      case 8453:
        return BaseClient();
      case 42161:
        return ArbitrumClient();
      default:
        return EVMChainClient(chainId: chainId);
    }
  }
}
