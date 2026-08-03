import "package:cw_core/erc20_token.dart";
import "package:cw_evm/tokens/arbitrum_tokens.dart";
import "package:cw_evm/tokens/base_tokens.dart";
import "package:cw_evm/tokens/bsc_tokens.dart";
import "package:cw_evm/tokens/ethereum_tokens.dart";
import "package:cw_evm/tokens/polygon_tokens.dart";
import "package:cw_evm/tokens/robinhood_tokens.dart";

/// Default ERC20 tokens for each EVM chain and utility methods for interacting with them
class EVMChainDefaultTokens {
  static List<Erc20Token> getDefaultTokensByChainId(int chainId) => switch (chainId) {
      1 => EthereumTokens.tokens,
      137 => PolygonTokens.tokens,
      8453 => BaseTokens.tokens,
      42161 => ArbitrumTokens.tokens,
      56 => BSCTokens.tokens,
      4663 => RobinhoodTokens.tokens,
      _ => [],
    };

  static List<String> getDefaultTokenAddresses(int chainId) => getDefaultTokensByChainId(chainId).map((token) => token.contractAddress).toList();

  static List<String> getDefaultTokenSymbols(int chainId) => getDefaultTokensByChainId(chainId).map((token) => token.symbol.toUpperCase()).toList();

  static final Map<int, Map<String, String>> _iconPathsByAddress = {};

  static String? getDefaultIconPathByAddress(int chainId, String contractAddress) {
    final iconPaths = _iconPathsByAddress.putIfAbsent(chainId, () {
      final paths = <String, String>{};

      for (final token in getDefaultTokensByChainId(chainId)) {
        final iconPath = token.iconPath;

        if (iconPath != null && iconPath.isNotEmpty) {
          paths[token.contractAddress.toLowerCase()] = iconPath;
        }
      }

      return paths;
    });

    return iconPaths[contractAddress.toLowerCase()];
  }
}
