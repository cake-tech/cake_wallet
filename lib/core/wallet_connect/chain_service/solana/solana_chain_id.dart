import 'solana_chain_service.dart';

enum SolanaChainId {
  mainnet,
  testnet,
  devnet,
}

extension SolanaChainIdX on SolanaChainId {
  String chain() {
    String name = '';

    switch (this) {
      case SolanaChainId.mainnet:
        name = '101';
        break;
      case SolanaChainId.testnet:
        name = '102';
        break;
      case SolanaChainId.devnet:
        name = '103';
        break;
    }

    return '${SolanaChainServiceImpl.namespace}:$name';
  }
}
