import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_chain_id.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_supported_methods.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_chain_id.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_supported_methods.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/evm/evm.dart';

bool isEVMCompatibleChain(WalletType walletType) {
  switch (walletType) {
    case WalletType.evm:
    case WalletType.polygon:
    case WalletType.ethereum:
    case WalletType.base:
    case WalletType.arbitrum:
      return true;
    default:
      return false;
  }
}

bool isNFTACtivatedChain(WalletType walletType) {
  switch (walletType) {
    case WalletType.evm:
    case WalletType.polygon:
    case WalletType.ethereum:
    case WalletType.base:
    case WalletType.solana:
    case WalletType.arbitrum:
      return true;
    default:
      return false;
  }
}

bool isWalletConnectCompatibleChain(WalletType walletType) {
  switch (walletType) {
    case WalletType.evm:
    case WalletType.solana:
    case WalletType.polygon:
    case WalletType.ethereum:
    case WalletType.base:
    case WalletType.arbitrum:
      return true;
    default:
      return false;
  }
}

String getChainNameSpaceAndIdBasedOnWalletType(WalletType walletType, {int? chainId}) {
  if (walletType == WalletType.evm) {
    if (chainId == null) {
      throw Exception('chainId required for WalletType.evm');
    }
    return evm!.getCaip2ByChainId(chainId);
  }
  
  switch (walletType) {
    case WalletType.ethereum:
      return EVMChainId.ethereum.chain();
    case WalletType.polygon:
      return EVMChainId.polygon.chain();
    case WalletType.base:
      return EVMChainId.base.chain();
    case WalletType.arbitrum:
      return EVMChainId.arbitrum.chain();
    case WalletType.solana:
      return SolanaChainId.mainnet.chain();
    default:
      return '';
  }
}

List<String> getChainSupportedMethodsOnWalletType(WalletType walletType) {
  switch (walletType) {
    case WalletType.evm:
    case WalletType.ethereum:
    case WalletType.polygon:
    case WalletType.base:
    case WalletType.arbitrum:
      return EVMSupportedMethods.values.map((e) => e.name).toList();
    case WalletType.solana:
      return SolanaSupportedMethods.values.map((e) => e.name).toList();
    default:
      return [];
  }
}

int getChainIdBasedOnWalletType(WalletType walletType, {int? chainId}) {
  if (walletType == WalletType.evm) {
    if (chainId == null) {
      throw Exception('chainId required for WalletType.evm');
    }
    return chainId;
  }
  return evm!.getChainIdByWalletType(walletType);
}

String getChainNameBasedOnWalletType(WalletType walletType, {int? chainId}) {
  if (walletType == WalletType.solana) {
    return 'mainnet';
  }
  
  if (walletType == WalletType.evm) {
    if (chainId == null) {
      throw Exception('chainId required for WalletType.evm');
    }
    return evm!.getChainNameByChainId(chainId);
  }
  
  return evm!.getChainNameByWalletType(walletType);
}

String getTokenNameBasedOnWalletType(WalletType walletType, {int? chainId}) {
  if (walletType == WalletType.solana) {
    return 'SOL';
  }
  
  if (walletType == WalletType.evm) {
    if (chainId == null) {
      throw Exception('chainId required for WalletType.evm');
    }
    return evm!.getTokenNameByChainId(chainId);
  }
  
  return evm!.getTokenNameByWalletType(walletType);
}
