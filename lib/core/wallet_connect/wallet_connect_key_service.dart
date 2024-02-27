import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/core/wallet_connect/models/chain_key_model.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';

abstract class WalletConnectKeyService {
  /// Returns a list of all the keys.
  List<ChainKeyModel> getKeys(WalletBase wallet);

  /// Returns a list of all the keys for a given chain id.
  /// If the chain is not found, returns an empty list.
  ///  - [chain]: The chain to get the keys for.
  List<ChainKeyModel> getKeysForChain(WalletBase wallet);
}

class KeyServiceImpl implements WalletConnectKeyService {
  static String _getPrivateKeyForWallet(WalletBase wallet) {
    switch (wallet.type) {
      case WalletType.ethereum:
        return ethereum!.getPrivateKey(wallet);
      case WalletType.polygon:
        return polygon!.getPrivateKey(wallet);
      case WalletType.solana:
        return solana!.getPrivateKey(wallet);
      default:
        return '';
    }
  }

  static String _getPublicKeyForWallet(WalletBase wallet) {
    switch (wallet.type) {
      case WalletType.ethereum:
        return ethereum!.getPublicKey(wallet);
      case WalletType.polygon:
        return polygon!.getPublicKey(wallet);
      case WalletType.solana:
        return solana!.getPublicKey(wallet);
      default:
        return '';
    }
  }

  @override
  List<ChainKeyModel> getKeys(WalletBase wallet) {
    final keys = [
      ChainKeyModel(
        chains: [
          'eip155:1',
          'eip155:5',
          'eip155:137',
          'eip155:42161',
          'eip155:80001',
        ],
        privateKey: _getPrivateKeyForWallet(wallet),
        publicKey: _getPublicKeyForWallet(wallet),
      ),
      ChainKeyModel(
        chains: [
          'solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ', // main-net
          'solana:8E9rvCKLFQia2Y35HXjjpWzj8weVo44K', // test-net
        ],
        privateKey: _getPrivateKeyForWallet(wallet),
        publicKey: _getPublicKeyForWallet(wallet),
      ),
    ];
    return keys;
  }

  @override
  List<ChainKeyModel> getKeysForChain(WalletBase wallet) {
    final chain = getChainNameSpaceAndIdBasedOnWalletType(wallet.type);

    final keys = getKeys(wallet);

    return keys.where((e) => e.chains.contains(chain)).toList();
  }
}
