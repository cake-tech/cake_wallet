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
        name = '4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ';
        break;
      case SolanaChainId.testnet:
        name = '8E9rvCKLFQia2Y35HXjjpWzj8weVo44K';
        break;
      case SolanaChainId.devnet:
        name = '';
        break;
    }

    return '${SolanaChainServiceImpl.namespace}:$name';
  }
}
