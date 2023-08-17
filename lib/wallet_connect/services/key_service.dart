import 'package:cake_wallet/ethereum/ethereum.dart';

import '../models/chain_key_model.dart';

abstract class WalletConnectKeyService {
  /// Returns a list of all the keys.
  List<ChainKeyModel> getKeys();

  /// Returns a list of all the chain ids.
  List<String> getChains();

  /// Returns a list of all the keys for a given chain id.
  /// If the chain is not found, returns an empty list.
  ///  - [chain]: The chain to get the keys for.
  List<ChainKeyModel> getKeysForChain(String chain);

  /// Returns a list of all the accounts in namespace:chainId:address format.
  List<String> getAllAccounts();
}

class KeyServiceImpl implements WalletConnectKeyService {
  final List<ChainKeyModel> keys = [
    ChainKeyModel(
      chains: [
        'eip155:1',
        'eip155:5',
        'eip155:137',
        'eip155:80001',
      ],
      privateKey: '415d3d81c550d9cc6794a5d842f5b819238570192254bdb7dd80885840be1963',
      publicKey: '0xeB900400cbaD60dACB53c1a37C11FE02AC49bf1C',
    )
  ];

  @override
  List<String> getChains() {
    final List<String> chainIds = [];
    for (final ChainKeyModel key in keys) {
      chainIds.addAll(key.chains);
    }
    return chainIds;
  }

  @override
  List<ChainKeyModel> getKeys() {
    return keys;
  }

  @override
  List<ChainKeyModel> getKeysForChain(String chain) {
    return keys.where((e) => e.chains.contains(chain)).toList();
  }

  @override
  List<String> getAllAccounts() {
    final List<String> accounts = [];
    for (final ChainKeyModel key in keys) {
      for (final String chain in key.chains) {
        accounts.add('$chain:${key.publicKey}');
      }
    }
    return accounts;
  }
}
