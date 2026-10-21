import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/chain_key_model.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';

abstract class WalletConnectKeyService {
  List<ChainKeyModel> getKeys(WalletBase wallet);
  List<ChainKeyModel> getKeysForChain(WalletBase wallet);
}

class KeyServiceImpl implements WalletConnectKeyService {
  static String _getPrivateKeyForWallet(WalletBase wallet) {
    if (isEVMCompatibleChain(wallet.type)) {
      return evm!.getPrivateKey(wallet);
    }

    if (wallet.type == WalletType.solana) {
      return solana!.getPrivateKey(wallet);
    }

    return "";
  }

  static String _getPublicKeyForWallet(WalletBase wallet) {
    if (isEVMCompatibleChain(wallet.type)) {
      return evm!.getPublicKey(wallet);
    }

    if (wallet.type == WalletType.solana) {
      return solana!.getPublicKey(wallet);
    }

    return "";
  }

  @override
  List<ChainKeyModel> getKeys(WalletBase wallet) {
    if (isEVMCompatibleChain(wallet.type)) {
      return [
        ChainKeyModel(
          chains:
              evm!.getAllChains().map((chain) => evm!.getCaip2ByChainId(chain.chainId)).toList(),
          privateKey: _getPrivateKeyForWallet(wallet),
          publicKey: _getPublicKeyForWallet(wallet),
        ),
      ];
    }

    if (wallet.type == WalletType.solana) {
      return [
        ChainKeyModel(
          chains: [
            'solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp', // main-net
            'solana:4sGjMW1sUnHzSxGspuhpqLDx6wiyjNtZ', // legacy main-net id older dapps still use
          ],
          privateKey: _getPrivateKeyForWallet(wallet),
          publicKey: _getPublicKeyForWallet(wallet),
        ),
      ];
    }

    return [];
  }

  @override
  List<ChainKeyModel> getKeysForChain(WalletBase wallet) {
    int? chainId;
    if (isEVMCompatibleChain(wallet.type)) {
      final chainInfo = evm!.getCurrentChain(wallet);
      chainId = chainInfo?.chainId;
    }
    final chain = getChainNameSpaceAndIdBasedOnWalletType(wallet.type, chainId: chainId);

    final keys = getKeys(wallet);

    return keys.where((e) => e.chains.contains(chain)).toList();
  }
}
