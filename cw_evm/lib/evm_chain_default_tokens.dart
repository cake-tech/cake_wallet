import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/tokens/arbitrum_tokens.dart';
import 'package:cw_evm/tokens/base_tokens.dart';
import 'package:cw_evm/tokens/ethereum_tokens.dart';
import 'package:cw_evm/tokens/polygon_tokens.dart';

/// Default ERC20 tokens for each EVM chain
class EVMChainDefaultTokens {
  static List<Erc20Token> getDefaultTokens(WalletType walletType, {int? chainId}) {
    if (walletType == WalletType.evm) {
      if (chainId == null) {
        throw Exception('chainId required for WalletType.evm');
      }
      return getDefaultTokensByChainId(chainId);
    }

    return switch (walletType) {
      WalletType.ethereum => EthereumTokens.tokens,
      WalletType.polygon => PolygonTokens.tokens,
      WalletType.base => BaseTokens.tokens,
      WalletType.arbitrum => ArbitrumTokens.tokens,
      _ => [],
    };
  }

  static List<Erc20Token> getDefaultTokensByChainId(int chainId) {
    return switch (chainId) {
      1 => EthereumTokens.tokens,
      137 => PolygonTokens.tokens,
      8453 => BaseTokens.tokens,
      42161 => ArbitrumTokens.tokens,
      _ => [],
    };
  }

  static List<String> getDefaultTokenAddresses(WalletType walletType, {int? chainId}) {
    return getDefaultTokens(walletType, chainId: chainId)
        .map((token) => token.contractAddress)
        .toList();
  }
}
