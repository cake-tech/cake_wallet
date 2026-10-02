import "package:collection/collection.dart";
import "package:cw_evm/.secrets.g.dart" as secrets;
import "package:cw_evm/clients/evm_chain_client.dart";
import "package:cw_evm/evm_chain_registry.dart";
import "package:cw_evm/history/blockscout_history_provider.dart";
import "package:cw_evm/history/etherscan_history_provider.dart";
import "package:cw_evm/history/evm_history_provider.dart";
import "package:cw_evm/history/moralis_history_provider.dart";

class EVMChainClientFactory {
  static final EvmChainRegistry _registry = EvmChainRegistry();

  static EVMChainClient createClient(int chainId) {
    final config = _registry.getChainConfig(chainId);

    if (config == null) {
      throw Exception("Chain config not found for chainId: $chainId");
    }

    final historyProvider =
        _historyProviders.firstWhereOrNull((provider) => provider.covers(chainId));

    return EVMChainClient(
      chainId: chainId,
      feeType: config.feeModel.type,
      historyProvider: historyProvider,
    );
  }

  static Uri? contractSourceCodeUri(int chainId, String contractAddress) {
    final explorer = _historyProviders
        .whereType<EtherscanHistoryProvider>()
        .firstWhereOrNull((provider) => provider.covers(chainId));

    return explorer?.queryUri(chainId, {
      "module": "contract",
      "action": "getsourcecode",
      "address": contractAddress,
    });
  }

  static final List<EvmHistoryProvider> _historyProviders = [
    EtherscanHistoryProvider(apiKey: secrets.etherScanApiKey),
    BlockscoutHistoryProvider(),
    MoralisHistoryProvider(apiKey: secrets.moralisApiKey),
  ];
}
