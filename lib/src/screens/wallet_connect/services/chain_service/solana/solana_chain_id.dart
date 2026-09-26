enum SolanaChainId { mainnet, mainnetLegacy, devnet, testnet }

extension SolanaChainIdX on SolanaChainId {
  String chain() {
    String name = '';

    switch (this) {
      case SolanaChainId.mainnet:
        name = "5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp";
        break;
      case SolanaChainId.mainnetLegacy:
        name = '4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ';
        break;
      case SolanaChainId.devnet:
        name = 'EtWTRABZaYq6iMfeYKouRu166VU2xqa1';
        break;
      case SolanaChainId.testnet:
        name = '4uhcVJyU9pJkvQyS88uRDiswHXSCkY3z';
        break;
    }

    return 'solana:$name';
  }
}
