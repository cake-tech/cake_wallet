enum StarknetChainId { mainnet }

extension StarknetChainIdX on StarknetChainId {
  String chain() {
    switch (this) {
      case StarknetChainId.mainnet:
        return 'starknet:SN_MAIN';
    }
  }
}
