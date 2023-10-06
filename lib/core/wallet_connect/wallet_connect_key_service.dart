import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/core/wallet_connect/models/chain_key_model.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';

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
  KeyServiceImpl(this.wallet)
      : _keys = [
          ChainKeyModel(
            chains: [
              'eip155:1',
              'eip155:5',
              'eip155:137',
              'eip155:42161',
              'eip155:80001',
            ],
            privateKey: ethereum!.getPrivateKey(wallet),
            publicKey: ethereum!.getPublicKey(wallet),
          ),
          
        ];

  late final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> wallet;

  late final List<ChainKeyModel> _keys;

  @override
  List<String> getChains() {
    final List<String> chainIds = [];
    for (final ChainKeyModel key in _keys) {
      chainIds.addAll(key.chains);
    }
    return chainIds;
  }

  @override
  List<ChainKeyModel> getKeys() => _keys;

  @override
  List<ChainKeyModel> getKeysForChain(String chain) {
    return _keys.where((e) => e.chains.contains(chain)).toList();
  }

  @override
  List<String> getAllAccounts() {
    final List<String> accounts = [];
    for (final ChainKeyModel key in _keys) {
      for (final String chain in key.chains) {
        accounts.add('$chain:${key.publicKey}');
      }
    }
    return accounts;
  }
}
