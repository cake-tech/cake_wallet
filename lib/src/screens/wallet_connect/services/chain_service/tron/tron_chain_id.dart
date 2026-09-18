enum TronChainId { mainnet }

extension TronChainIdX on TronChainId {
  String chain() {
    String name = "";

    switch (this) {
      case TronChainId.mainnet:
        name = "0x2b6653dc";
        break;
    }

    return "tron:$name";
  }
}
