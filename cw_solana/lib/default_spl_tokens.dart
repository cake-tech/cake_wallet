import 'package:cw_core/crypto_currency.dart';
import 'package:cw_solana/spl_token.dart';

class DefaultSPLTokens {
  final List<SPLToken> _defaultTokens = [
    SPLToken(
      name: 'USDT',
      symbol: 'USDT',
      mintAddress: 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB',
      decimal: 6,
      mint: 'usdt',
      enabled: true,
    ),
    SPLToken(
      name: 'USD Coin',
      symbol: 'USDC',
      mintAddress: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
      decimal: 6,
      mint: 'usdc',
      enabled: true,
    ),
    SPLToken(
      name: 'Wrapped Ethereum (Sollet)',
      symbol: 'soETH',
      mintAddress: '2FPyTwcZLUg1MDrwsyoP4D6s1tM7hAkHYRjkNb5w6Pxk',
      decimal: 6,
      mint: 'soEth',
      enabled: true,
    ),
    SPLToken(
      name: 'Wrapped SOL',
      symbol: 'WSOL',
      mintAddress: 'So11111111111111111111111111111111111111112',
      decimal: 9,
      mint: 'WSOL',
      enabled: true,
    ),
    SPLToken(
      name: 'Wrapped Bitcoin (Sollet)',
      symbol: 'BTC',
      mintAddress: '9n4nbM75f5Ui33ZbPYXn59EwSgE8CGsHtAeTH5YFeJ9E',
      decimal: 6,
      mint: 'btc',
    ),
    SPLToken(
      name: 'Bonk',
      symbol: 'Bonk',
      mintAddress: 'DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263',
      decimal: 5,
      mint: 'Bonk',
    ),
    SPLToken(
      name: 'Helium Network Token',
      symbol: 'HNT',
      mintAddress: 'hntyVP6YFm1Hg25TN9WGLqM12b8TQmcknKrdu1oxWux',
      decimal: 8,
      mint: 'hnt',
    ),
    SPLToken(
      name: 'Pyth Network',
      symbol: 'PYTH',
      mintAddress: 'HZ1JovNiVvGrGNiiYvEozEVgZ58xaU3RKwX8eACQBCt3',
      decimal: 6,
      mint: 'pyth',
    ),
    SPLToken(
      name: 'Raydium',
      symbol: 'RAY',
      mintAddress: '4k3Dyjzvzp8eMZWUXbBCjEvwSkkk59S5iCNLY3QrkX6R',
      decimal: 6,
      mint: 'ray',
    ),
    SPLToken(
      name: 'GMT',
      symbol: 'GMT',
      mintAddress: '7i5KKsX2weiTkry7jA4ZwSuXGhs5eJBEjY8vVxR4pfRx',
      decimal: 6,
      mint: 'ray',
    ),
    SPLToken(
      name: 'AvocadoCoin',
      symbol: 'AVDO',
      mintAddress: 'EE5L8cMU4itTsCSuor7NLK6RZx6JhsBe8GGV3oaAHm3P',
      decimal: 8,
      mint: 'avdo',
    ),
  ];

  List<SPLToken> get initialSPLTokens => _defaultTokens.map((token) {
        String? iconPath;
        try {
          iconPath = CryptoCurrency.all
              .firstWhere((element) => element.title.toUpperCase() == token.symbol.toUpperCase())
              .iconPath;
        } catch (_) {}

        return SPLToken.copyWith(token, iconPath, 'SOL');
      }).toList();
}
