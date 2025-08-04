enum EVMChainId {
  ethereum,
  polygon,
  goerli,
  mumbai,
  arbitrum,
}

extension EVMChainIdX on EVMChainId {
  String chain() {
    String name = '';

    switch (this) {
      case EVMChainId.ethereum:
        name = '1';
        break;
      case EVMChainId.polygon:
        name = '137';
        break;
      case EVMChainId.goerli:
        name = '5';
        break;
      case EVMChainId.arbitrum:
        name = '42161';
        break;
      case EVMChainId.mumbai:
        name = '80001';
        break;
    }

    return 'eip155:$name';
  }
}
