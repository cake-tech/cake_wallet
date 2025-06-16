import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';

class DefaultGnosisErc20Tokens {
  final List<Erc20Token> _defaultTokens = [
    Erc20Token(
      name: "Wrapped Ether",
      symbol: "WETH",
      contractAddress: "0x6a023ccd1ff6f2045c3309768ead9e68f978f6e1",
      decimal: 18,
      enabled: false,
    ),
    Erc20Token(
      name: "Tether USD on xDai",
      symbol: "USDT",
      contractAddress: "0x4ECaBa5870353805a9F068101A40E0f32ed605C6",
      decimal: 6,
      enabled: true,
    ),
    Erc20Token(
      name: "USD Coin",
      symbol: "USDC.e",
      contractAddress: "0x2a22f9c3b484c3629090FeED35F17Ff8F88f76F0",
      decimal: 6,
      enabled: true,
    ),
    Erc20Token(
      name: "Gnosis",
      symbol: "GNO",
      contractAddress: "0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb",
      decimal: 18,
      enabled: true,
    ),
    Erc20Token(
      name: "Decentralized Euro",
      symbol: "DEURO",
      contractAddress: "0xac90f343820D8299Ac72a06A7674491b07d45f03",
      decimal: 18,
      enabled: true,
    ),
  ];

  List<Erc20Token> get initialGnosisErc20Tokens => _defaultTokens.map((token) {
        String? iconPath;
        try {
          iconPath = CryptoCurrency.all
              .firstWhere((element) =>
                  element.title.toUpperCase() == token.symbol.split(".").first.toUpperCase())
              .iconPath;
        } catch (_) {}

        return Erc20Token.copyWith(token, iconPath, 'XDAI');
      }).toList();
}
