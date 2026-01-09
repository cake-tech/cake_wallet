import 'package:cake_wallet/evm/evm.dart';

enum EVMChainId {
  ethereum,
  polygon,
  base,
  arbitrum,
}

extension EVMChainIdX on EVMChainId {
  String chain() {
    final chainId = _getChainIdForEnum(this);

    if (chainId == null) return 'eip155:1';

    return evm!.getCaip2ByChainId(chainId);
  }

  int? _getChainIdForEnum(EVMChainId id) {
    return switch (id) {
      EVMChainId.ethereum => 1,
      EVMChainId.polygon => 137,
      EVMChainId.base => 8453,
      EVMChainId.arbitrum => 42161,
    };
  }

  int? get chainId => _getChainIdForEnum(this);
}
