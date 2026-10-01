import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/eth/evm_supported_methods.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_chain_id.dart';
import 'package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_supported_methods.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/evm/evm.dart';

const List<WalletType> walletConnectCompatibleChains = [
  WalletType.ethereum,
  WalletType.polygon,
  WalletType.base,
  WalletType.arbitrum,
  WalletType.bsc,
  WalletType.evm,
  WalletType.solana,
];

String walletConnectCompatibleChainsLabel() {
  final names = walletConnectCompatibleChains
      .where((type) => type != WalletType.evm)
      .map(walletTypeToDisplayName)
      .toList();
  if (names.length <= 1) return names.join();
  final head = names.sublist(0, names.length - 1).join(', ');
  return '$head, and ${names.last}';
}

String networkDisplayName(WalletType type, int? chainId) {
  if (evm != null && isEVMCompatibleChain(type)) {
    final id = chainId ?? evm!.getChainIdByWalletType(type);
    final info = evm!.getChainInfoByChainId(id);
    if (info != null) {
      return info.name;
    }
  }
  return walletTypeToString(type);
}

bool isEVMCompatibleChain(WalletType walletType) {
  switch (walletType) {
    case WalletType.polygon:
    case WalletType.ethereum:
    case WalletType.evm:
    case WalletType.base:
    case WalletType.arbitrum:
    case WalletType.bsc:
      return true;
    default:
      return false;
  }
}

// Blink Protection is supported on Ethereum and Base chains
bool canSupportBlinkProtection(int? chainId) {
  if (chainId == null) return false;

  return chainId == 1 || chainId == 8453;
}

bool isNFTACtivatedChain(WalletType walletType, {int? chainId}) {
  if (chainId != null) {
    return evm?.isMoralisSupportedChain(chainId) ?? false;
  }

  switch (walletType) {
    case WalletType.solana:
      return true;
    default:
      return false;
  }
}

bool isWalletConnectCompatibleChain(WalletType walletType) =>
    walletConnectCompatibleChains.contains(walletType);

String getChainNameSpaceAndIdBasedOnWalletType(WalletType walletType, {int? chainId}) {
  if (walletType == WalletType.solana) {
    return SolanaChainId.mainnet.chain();
  }

  if (!isEVMCompatibleChain(walletType)) {
    return "";
  }

  return evm!.getCaip2ByChainId(chainId ?? evm!.getChainIdByWalletType(walletType));
}

List<String> getChainSupportedMethodsOnWalletType(WalletType walletType) {
  if (isEVMCompatibleChain(walletType)) {
    return EVMSupportedMethods.values.map((e) => e.name).toList();
  }

  if (walletType == WalletType.solana) {
    return SolanaSupportedMethods.values.map((e) => e.name).toList();
  }

  return [];
}

String getChainNameBasedOnWalletType(WalletType walletType, {int? chainId}) {
  if (walletType == WalletType.solana) {
    return 'mainnet';
  }

  if (chainId != null) {
    return evm!.getChainNameByChainId(chainId);
  }

  return evm!.getChainNameByWalletType(walletType);
}
