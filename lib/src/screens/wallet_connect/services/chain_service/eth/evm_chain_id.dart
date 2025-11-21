import 'package:cake_wallet/evm/evm.dart';

enum EVMChainId {
  ethereum,
  polygon,
  base,
  goerli,
  mumbai,
  arbitrum,
}

extension EVMChainIdX on EVMChainId {
  String chain() {
    final chainId = _getChainIdForEnum(this);

    if (chainId == null) {
      return switch (this) {
        EVMChainId.goerli => 'eip155:5',
        EVMChainId.mumbai => 'eip155:80001',
        _ => 'eip155:1', // Default to Ethereum
      };
    }

    return evm!.getCaip2ByChainId(chainId);
  }

  int? _getChainIdForEnum(EVMChainId id) {
    return switch (id) {
      EVMChainId.ethereum => 1,
      EVMChainId.polygon => 137,
      EVMChainId.base => 8453,
      EVMChainId.arbitrum => 42161,
      _ => null,
    };
  }

  int? get chainId => _getChainIdForEnum(this);
}
