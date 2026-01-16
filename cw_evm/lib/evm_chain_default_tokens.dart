import 'package:cw_core/erc20_token.dart';
import 'package:cw_evm/tokens/arbitrum_tokens.dart';
import 'package:cw_evm/tokens/base_tokens.dart';
import 'package:cw_evm/tokens/ethereum_tokens.dart';
import 'package:cw_evm/tokens/polygon_tokens.dart';

/// Default ERC20 tokens for each EVM chain
class EVMChainDefaultTokens {
  static List<Erc20Token> getDefaultTokensByChainId(int chainId) {
    return switch (chainId) {
      1 => EthereumTokens.tokens,
      137 => PolygonTokens.tokens,
      8453 => BaseTokens.tokens,
      42161 => ArbitrumTokens.tokens,
      _ => [],
    };
  }

  static List<String> getDefaultTokenAddresses(int chainId) {
    return getDefaultTokensByChainId(chainId).map((token) => token.contractAddress).toList();
  }
}
