import 'solana_chain_service.dart';

enum SolanaChainId {
  mainnet,
  // testnet,
  // devnet,
}

extension SolanaChainIdX on SolanaChainId {
  String chain() {
    String name = '';

    switch (this) {
      case SolanaChainId.mainnet:
        name = '4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ';
        // solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp
        break;
      // case SolanaChainId.devnet:
      //   name = '8E9rvCKLFQia2Y35HXjjpWzj8weVo44K';
      //   // solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1
      //   break;
      // case SolanaChainId.testnet:
      //   name = '';
      //   // solana:4uhcVJyU9pJkvQyS88uRDiswHXSCkY3z
      //   break;
    }

    return '${SolanaChainServiceImpl.namespace}:$name';
  }
}
