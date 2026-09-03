import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/tron/tron_chain_id.dart";
import 'package:cake_wallet/src/screens/wallet_connect/services/key_service/chain_key_model.dart';
import "package:cake_wallet/tron/tron.dart";
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';

abstract class WalletConnectKeyService {
  List<ChainKeyModel> getKeys(WalletBase wallet);
  List<ChainKeyModel> getKeysForChain(WalletBase wallet);
}

class KeyServiceImpl implements WalletConnectKeyService {
  static String _getPrivateKeyForWallet(WalletBase wallet) {
    switch (wallet.type) {
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
        return evm!.getPrivateKey(wallet);
      case WalletType.solana:
        return solana!.getPrivateKey(wallet);
      case WalletType.tron:
        return wallet.privateKey ?? "";
      default:
        return '';
    }
  }

  static String _getPublicKeyForWallet(WalletBase wallet) {
    switch (wallet.type) {
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
        return evm!.getPublicKey(wallet);
      case WalletType.solana:
        return solana!.getPublicKey(wallet);
      case WalletType.tron:
        return tron!.getAddress(wallet);
      default:
        return '';
    }
  }

  @override
  List<ChainKeyModel> getKeys(WalletBase wallet) {
    if (isEVMCompatibleChain(wallet.type)) {
      return [
        ChainKeyModel(
          chains: [
            'eip155:1',
            'eip155:56',
            'eip155:137',
            'eip155:8453',
            'eip155:42161',
          ],
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

    if (wallet.type == WalletType.tron) {
      return [
        ChainKeyModel(
          chains: [TronChainId.mainnet.chain()],
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
