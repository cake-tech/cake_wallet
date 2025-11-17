import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/tokens/arbitrum_tokens.dart';
import 'package:cw_evm/tokens/base_tokens.dart';
import 'package:cw_evm/tokens/ethereum_tokens.dart';
import 'package:cw_evm/tokens/polygon_tokens.dart';

/// Default ERC20 tokens for each EVM chain
class EVMChainDefaultTokens {
  /// Get default tokens for a wallet type
  static List<Erc20Token> getDefaultTokens(WalletType walletType) {
    return switch (walletType) {
      WalletType.ethereum => EthereumTokens.tokens,
      WalletType.polygon => PolygonTokens.tokens,
      WalletType.base => BaseTokens.tokens,
      WalletType.arbitrum => ArbitrumTokens.tokens,
      _ => [],
    };
  }

  /// Get default token contract addresses for a wallet type
  static List<String> getDefaultTokenAddresses(WalletType walletType) {
    return getDefaultTokens(walletType)
        .map((token) => token.contractAddress)
        .toList();
  }
}
