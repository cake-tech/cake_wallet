import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';

class DefaultArbitrumErc20Tokens {
  final List<Erc20Token> _defaultTokens = [
    Erc20Token(
      name: "USD Coin",
      symbol: "USDC",
      contractAddress: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
      decimal: 6,
      enabled: true,
    ),
    Erc20Token(
      name: "USDC.e",
      symbol: "USDC.e",
      contractAddress: "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
      decimal: 6,
      enabled: true,
    ),
    Erc20Token(
      name: "Wrapped BTC",
      symbol: "WBTC",
      contractAddress: "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f",
      decimal: 8,
      enabled: true,
    ),
    Erc20Token(
      name: "Chainlink Token",
      symbol: "LINK",
      contractAddress: "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4",
      decimal: 18,
      enabled: true,
    ),
    Erc20Token(
      name: "Wrapped liquid staked Ether 2.0",
      symbol: "wstETH",
      contractAddress: "0x0fBcbaEA96Ce0cF7Ee00A8c19c3ab6f5Dc8E1921",
      decimal: 18,
      enabled: false,
    ),
    Erc20Token(
      name: "Wrapped Ether",
      symbol: "WETH",
      contractAddress: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
      decimal: 18,
      enabled: false,
    ),
    Erc20Token(
      name: "DAI",
      symbol: "DAI",
      contractAddress: "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
      decimal: 18,
      enabled: false,
    ),
  ];

  List<Erc20Token> get initialArbitrumErc20Tokens => _defaultTokens.map((token) {
        String? iconPath;
        try {
          iconPath = CryptoCurrency.all
              .firstWhere((element) => element.title.toUpperCase() == token.symbol.toUpperCase())
              .iconPath;
        } catch (_) {}

        return Erc20Token.copyWith(token, iconPath, 'ARB');
      }).toList();
}
