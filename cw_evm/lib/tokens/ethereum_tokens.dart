import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';

/// Default ERC20 tokens for Ethereum Mainnet
class EthereumTokens {
  static List<Erc20Token> get tokens {
    final tokens = [
      Erc20Token(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        decimal: 6,
        enabled: true,
      ),
      Erc20Token(
        name: "USDT Tether",
        symbol: "USDT",
        contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
        decimal: 6,
        enabled: true,
      ),
      Erc20Token(
        name: "Decentralized Euro",
        symbol: "DEURO",
        contractAddress: "0xba3f535bbcccca2a154b573ca6c5a49baae0a3ea",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "Dai",
        symbol: "DAI",
        contractAddress: "0x6b175474e89094c44da98b954eedeac495271d0f",
        decimal: 18,
        enabled: true,
      ),
      Erc20Token(
        name: "Ethena USDE",
        symbol: "USDe",
        contractAddress: "0x4c9edd5852cd905f086c759e8383e09bff1e68b3",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Sky Dollar",
        symbol: "USDS",
        contractAddress: "0xdc035d45d973e3ec169d2276ddab16f1e407384f",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "World Liberty Financial USD",
        symbol: "USD1",
        contractAddress: "0x8d0d000ee44948fc98c9b98a4fa4921476f08b0d",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Global Dollar",
        symbol: "USDG",
        contractAddress: "0xe343167631d89b6ffc58b88d6b7fb0228795491d",
        decimal: 6,
        enabled: false,
      ),
      Erc20Token(
        name: "PayPal USD",
        symbol: "PYUSD",
        contractAddress: "0x6c3ea9036406852006290770bedfcaba0e23a0e8",
        decimal: 6,
        enabled: false,
      ),
      Erc20Token(
        name: "Ripple USD",
        symbol: "RLUSD",
        contractAddress: "0x8292bb45bf1ee4d140127049757c2e0ff06317ed",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "EURC",
        symbol: "EURC",
        contractAddress: "0x1abaea1f7c830bd89acc67ec4af516284b1bc33c",
        decimal: 6,
        enabled: false,
      ),
      Erc20Token(
        name: "Wrapped Ether",
        symbol: "WETH",
        contractAddress: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Pepe",
        symbol: "PEPE",
        contractAddress: "0x6982508145454ce325ddbe47a25d4ec3d2311933",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "SHIBA INU",
        symbol: "SHIB",
        contractAddress: "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "ApeCoin",
        symbol: "APE",
        contractAddress: "0x4d224452801aced8b2f0aebe155379bb5d594381",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Matic Token",
        symbol: "MATIC",
        contractAddress: "0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Wrapped BTC",
        symbol: "WBTC",
        contractAddress: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
        decimal: 8,
        enabled: false,
      ),
      Erc20Token(
        name: "Paxos Gold",
        symbol: "PAXG",
        contractAddress: "0x45804880de22913dafe09f4980848ece6ecbaf78",
        decimal: 18,
        enabled: false,
      ),
      Erc20Token(
        name: "Tether Gold",
        symbol: "XAUT",
        contractAddress: "0x68749665ff8d2d112fa859aa293f07a622782f38",
        decimal: 6,
        enabled: false,
        iconPath: "assets/images/xaut.webp",
      ),
    ];

    return tokens.map((token) {
      String? iconPath;
      if (token.iconPath?.isEmpty ?? true) {
        try {
          iconPath = CryptoCurrency.all
              .firstWhere((element) => element.title.toUpperCase() == token.symbol.toUpperCase())
              .iconPath;
        } catch (_) {}
      } else {
        iconPath = token.iconPath;
      }

      return Erc20Token.copyWith(token, icon: iconPath, tag: 'ETH');
    }).toList();
  }
}
