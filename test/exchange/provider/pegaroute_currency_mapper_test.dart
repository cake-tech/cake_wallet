import 'package:flutter_test/flutter_test.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_currency_mapper.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/spl_token.dart';
import 'package:cw_core/tron_token.dart';

class _DerivedCurrency extends CryptoCurrency {
  const _DerivedCurrency() : super(title: 'ETH', name: 'derived-eth', tag: 'ETH', decimals: 18);
}

void main() {
  const mapper = PegarouteCurrencyMapper();

  test('maps native aliases to exact canonical identifiers', () {
    expect(mapper.map(CryptoCurrency.avaxc).chain, 'AVAX');
    expect(mapper.map(CryptoCurrency.avaxc).token, 'AVAX');
    expect(mapper.map(CryptoCurrency.maticpoly).chain, 'POLYGON');
    expect(mapper.map(CryptoCurrency.maticpoly).token, 'POL');
    expect(mapper.map(CryptoCurrency.trx).chain, 'TRON');
    expect(mapper.map(CryptoCurrency.bnb).chain, 'BSC');
  });

  test('all native catalog tuples retain their exact token identity', () {
    expect(PegarouteCurrencyMapper.nativeTokenByChain, hasLength(19));
    for (final entry in PegarouteCurrencyMapper.nativeTokenByChain.entries) {
      final asset = mapper.validateCanonicalTuple(
          chain: entry.key, token: entry.value, nativeToken: entry.value);
      expect(asset.chain, entry.key);
      expect(asset.token, entry.value);
      expect(asset.nativeToken, entry.value);
      expect(() => mapper.validateCanonicalTuple(
          chain: entry.key, token: 'UNKNOWN', nativeToken: entry.value),
          throwsA(isA<PegarouteCurrencyException>()));
      expect(() => mapper.validateCanonicalTuple(
          chain: entry.key, token: entry.value, nativeToken: 'UNKNOWN'),
          throwsA(isA<PegarouteCurrencyException>()));
    }
  });

  test('preserves exact contract-qualified EVM identity', () {
    final token = Erc20Token(
      name: 'USD Coin',
      symbol: 'USDC',
      contractAddress: '0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
      decimal: 6,
      tag: 'ETH',
    );
    final asset = mapper.map(token);
    expect(asset.chain, 'ETH');
    expect(asset.token, 'USDC-0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48');
  });

  test('rejects syntactically valid but non-catalog EVM identities', () {
    final token = Erc20Token(
      name: 'Fixture',
      symbol: 'FIX',
      contractAddress: '0x00000000000000000000000000000000000000Ab',
      decimal: 18,
      tag: 'ETH',
    );
    expect(() => mapper.map(token), throwsA(isA<PegarouteCurrencyException>()));
  });

  test('rejects missing or conflicting token identity', () {
    expect(
      () => mapper.map(Erc20Token(
        name: 'Fixture',
        symbol: 'FIX',
        contractAddress: '',
        decimal: 6,
        tag: 'ETH',
      )),
      throwsA(isA<PegarouteCurrencyException>()),
    );
    expect(
      () => mapper.map(Erc20Token(
        name: 'Fixture',
        symbol: 'FIX',
        contractAddress: '0x00000000000000000000000000000000000000ab',
        decimal: 6,
        tag: 'ETH',
        chainId: 137,
      )),
      throwsA(isA<PegarouteCurrencyException>()),
    );
    expect(
      () => mapper.map(Erc20Token(
        name: 'Fixture',
        symbol: 'FIX',
        contractAddress: '0xabc',
        decimal: 6,
        tag: 'ETH',
      )),
      throwsA(isA<PegarouteCurrencyException>()),
    );
    expect(
      () => mapper.map(Erc20Token(
        name: 'Fixture',
        symbol: 'USDC',
        contractAddress: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
        decimal: 6,
        tag: 'ETH',
        chainId: 10,
      )),
      throwsA(isA<PegarouteCurrencyException>()),
    );
  });

  test('maps cataloged Stellar and THOR natives', () {
    expect(mapper.map(CryptoCurrency.xlm).token, 'XLM');
    expect(mapper.map(CryptoCurrency.rune).token, 'RUNE');
  });

  test('maps cataloged built-in aliases to exact identities', () {
    final cases = <CryptoCurrency, String>{
      CryptoCurrency.ape: 'ETH/APE-0x4d224452801aced8b2f0aebe155379bb5d594381',
      CryptoCurrency.dai: 'ETH/DAI-0x6b175474e89094c44da98b954eedeac495271d0f',
      CryptoCurrency.matic: 'ETH/MATIC-0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0',
      CryptoCurrency.wbtc: 'ETH/WBTC-0x2260fac5e5542a773aa44fbcfedf7c193bc2c599',
      CryptoCurrency.weth: 'ETH/WETH-0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
      CryptoCurrency.usdterc20: 'ETH/USDT-0xdac17f958d2ee523a2206206994597c13d831ec7',
      CryptoCurrency.usdtPoly: 'POLYGON/USDT-0xc2132d05d31c914a87c6611c10748aeb04b58e8f',
      CryptoCurrency.usdcEPoly: 'POLYGON/USDC.E-0x2791bca1f2de4661ed88a30c99a7a9449aa84174',
      CryptoCurrency.usdtbsc: 'BSC/USDT-0x55d398326f99059ff775485246999027b3197955',
      CryptoCurrency.usde: 'BASE/USDE-0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34',
      CryptoCurrency.usdcArb: 'ARBITRUM/USDC-0xaf88d065e77c8cc2239327c5edb3a432268e5831',
      CryptoCurrency.usdtArb: 'ARBITRUM/USDT-0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9',
      CryptoCurrency.pepe: 'ETH/PEPE-0x6982508145454ce325ddbe47a25d4ec3d2311933',
      CryptoCurrency.shib: 'ETH/SHIB-0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce',
      CryptoCurrency.paxg: 'ETH/PAXG-0x45804880de22913dafe09f4980848ece6ecbaf78',
    };
    for (final entry in cases.entries) {
      final asset = mapper.map(entry.key);
      expect('${asset.chain}/${asset.token}', entry.value);
    }
  });

  test('maps cataloged SPL defaults without changing address case', () {
    final cases = <Map<String, String>>[
      {'symbol': 'PYTH', 'mint': 'HZ1JovNiVvGrGNiiYvEozEVgZ58xaU3RKwX8eACQBCt3'},
      {'symbol': 'GMT', 'mint': '7i5KKsX2weiTkry7jA4ZwSuXGhs5eJBEjY8vVxR4pfRx'},
      {'symbol': 'TBB', 'mint': '42cXQvAAr7hcPBPWAS4ocVtDyeJ4Fa6gRR2uG4gppump'},
      {'symbol': 'GOOGLx', 'mint': 'XsCPL9dNWBMvFtTmwcCA5v3xWPSMEBCszbQdiLLq6aN'},
      {'symbol': 'AMZNx', 'mint': 'Xs3eBt7uRfJX8QUs4suhyU8p2M6DoUDrJyWBa8LLZsg'},
      {'symbol': 'AAPLx', 'mint': 'XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp'},
      {'symbol': 'CRCLx', 'mint': 'XsueG8BtpquVJX9LVLLEGuViXUungE6WmK5YZ3p3bd1'},
      {'symbol': 'COINx', 'mint': 'Xs7ZdzSHLU9ftNJsii5fCeJhoRWSC32SQGzGQtePxNu'},
      {'symbol': 'DFDVx', 'mint': 'Xs2yquAgsHByNzx68WJC55WHjHBvG9JsMB7CWjTLyPy'},
      {'symbol': 'MCDx', 'mint': 'XsqE9cRRpzxcGKDXj1BJ7Xmg4GRhZoyY1KpmGSxAWT2'},
      {'symbol': 'METAx', 'mint': 'Xsa62P5mvPszXL1krVUnU5ar38bBSVcWAB6fmPCo5Zu'},
      {'symbol': 'MSTRx', 'mint': 'XsP7xzNPvEHS1m6qfanPUGjNmdnmsLKEoNAnHjdxxyZ'},
      {'symbol': 'QQQx', 'mint': 'Xs8S1uUs1zvS2p7iwtsG3b6fkhpvmwz4GYU3gWAmWHZ'},
      {'symbol': 'NVDAx', 'mint': 'Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh'},
      {'symbol': 'PGx', 'mint': 'XsYdjDjNUygZ7yGKfQaB6TxLh2gC6RRjzLtLAGJrhzV'},
      {'symbol': 'SPYx', 'mint': 'XsoCS1TfEyfFhfvj8EtZ528L3CaKBDBRqRapnBbDF2W'},
      {'symbol': 'TSLAx', 'mint': 'XsDoVfqeBukxuZHWhdvWHBhgEHjGNst4MLodqsJHzoB'},
      {'symbol': 'UNHx', 'mint': 'XszvaiXGPwvk2nwb3o9C1CX4K6zH8sez11E6uyup6fe'},
    ];
    for (final value in cases) {
      final asset = mapper.map(SPLToken(
        name: value['symbol']!,
        symbol: value['symbol']!,
        mintAddress: value['mint']!,
        decimal: 8,
        mint: value['symbol']!,
      ));
      expect('${asset.chain}/${asset.token}',
          'SOL/${value['symbol']!.toUpperCase()}-${value['mint']}');
    }
  });

  test('rejects unsupported native and case-sensitive token identities', () {
    expect(() => mapper.map(CryptoCurrency.near), throwsA(isA<PegarouteCurrencyException>()));
    expect(() => mapper.map(CryptoCurrency.ltcmweb), throwsA(isA<PegarouteCurrencyException>()));
    expect(
      () => mapper.map(SPLToken(
        name: 'Fixture',
        symbol: 'FIX',
        mintAddress: 'MintAddress123',
        decimal: 6,
        mint: 'fix',
      )),
      throwsA(isA<PegarouteCurrencyException>()),
    );
    expect(
      () => mapper.map(TronToken(
        name: 'USDT',
        symbol: 'USDT',
        contractAddress: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
        decimal: 6,
      )),
      throwsA(isA<PegarouteCurrencyException>()),
    );
    expect(() => mapper.map(CryptoCurrency.usdttrc20), throwsA(isA<PegarouteCurrencyException>()));
    expect(() => mapper.map(CryptoCurrency.usdcTrc20), throwsA(isA<PegarouteCurrencyException>()));
  });

  test('uses generic aliases only for base currencies', () {
    expect(
      mapper
          .map(const CryptoCurrency(
            title: 'ETH',
            name: 'restored-eth',
            tag: 'ETH',
            decimals: 18,
          ))
          .token,
      'ETH',
    );
    expect(
      () => mapper.map(const _DerivedCurrency()),
      throwsA(isA<PegarouteCurrencyException>()),
    );
  });
}
