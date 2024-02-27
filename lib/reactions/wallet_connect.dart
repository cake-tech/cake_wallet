import 'package:cake_wallet/core/wallet_connect/chain_service/eth/evm_chain_id.dart';
import 'package:cake_wallet/core/wallet_connect/chain_service/solana/solana_chain_id.dart';
import 'package:cw_core/wallet_type.dart';

bool isEVMCompatibleChain(WalletType walletType) {
  switch (walletType) {
    case WalletType.polygon:
    case WalletType.ethereum:
      return true;
    default:
      return false;
  }
}

bool isWalletConnectCompatibleChain(WalletType walletType) {
  switch (walletType) {
    case WalletType.polygon:
    case WalletType.ethereum:
      return true;
    default:
      return false;
  }
}

String getChainNameSpaceAndIdBasedOnWalletType(WalletType walletType) {
  switch (walletType) {
    case WalletType.ethereum:
      return EVMChainId.ethereum.chain();
    case WalletType.polygon:
      return EVMChainId.polygon.chain();
    case WalletType.solana:
      return SolanaChainId.mainnet.chain();
    default:
      return '';
  }
}

int getChainIdBasedOnWalletType(WalletType walletType) {
  switch (walletType) {
    case WalletType.polygon:
      return 137;

    // For now, we return eth chain Id as the default, we'll modify as we add more wallets
    case WalletType.ethereum:
    default:
      return 1;
  }
}

String getChainNameBasedOnWalletType(WalletType walletType) {
  switch (walletType) {
    case WalletType.ethereum:
      return 'eth';
    case WalletType.polygon:
      return 'polygon';
    case WalletType.solana:
      return 'solana';
    default:
      return '';
  }
}

String getTokenNameBasedOnWalletType(WalletType walletType) {
  switch (walletType) {
    case WalletType.ethereum:
      return 'ETH';
    case WalletType.polygon:
      return 'MATIC';
    case WalletType.solana:
      return 'SOL';
    default:
      return '';
  }
}
