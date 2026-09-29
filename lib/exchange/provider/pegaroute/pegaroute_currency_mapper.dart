import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/spl_token.dart';
import 'package:cw_core/tron_token.dart';

class PegarouteCurrencyException implements Exception {
  const PegarouteCurrencyException(this.message);

  final String message;

  @override
  String toString() => 'Unsupported Pegaroute currency: $message';
}

class PegarouteAssetId {
  const PegarouteAssetId({required this.chain, required this.token, required this.nativeToken});

  final String chain;
  final String token;
  final String nativeToken;
}

class PegarouteCurrencyMapper {
  const PegarouteCurrencyMapper();

  static const quoteSourceChains = {
    'BTC',
    'ETH',
    'XMR',
    'BCH',
    'LTC',
    'DOGE',
    'ZEC',
    'BSC',
    'BASE',
    'ARBITRUM',
    'POLYGON',
    'SOL',
    'TRON',
  };

  static const nativeTokenByChain = <String, String>{
    'ETH': 'ETH',
    'BSC': 'BNB',
    'POLYGON': 'POL',
    'AVAX': 'AVAX',
    'ARBITRUM': 'ETH',
    'BASE': 'ETH',
    'BTC': 'BTC',
    'BCH': 'BCH',
    'LTC': 'LTC',
    'DOGE': 'DOGE',
    'DASH': 'DASH',
    'ZEC': 'ZEC',
    'XMR': 'XMR',
    'XRP': 'XRP',
    'TRON': 'TRX',
    'SOL': 'SOL',
    'CARDANO': 'ADA',
    'STELLAR': 'XLM',
    'THOR': 'RUNE',
  };

  // Cake asset intersection target: src/catalog/pegaroute.json at v0.5.3.
  // Last review: 177d6891aada4659ca9d24cf3de8cb336ce31442; this label change
  // is not a new catalog audit. Unknown user tokens must not become request IDs.
  static final _catalogAssets = Set<String>.unmodifiable({
    for (final entry in nativeTokenByChain.entries) '${entry.key}/${entry.value}',
    ..._genericAliases.values,
    'ETH/XAUT-0x68749665ff8d2d112fa859aa293f07a622782f38',
    'ARBITRUM/USDC.E-0xff970a61a04b1ca14834a43f5de4533ebddb5cc8',
    'ARBITRUM/WBTC-0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f',
    'ARBITRUM/WETH-0x82af49447d8a07e3bd95bd0d56f35241523fbab1',
    'ARBITRUM/DAI-0xda10009cbd5d07dd0cecc66161fc93d7c9000da1',
    'ARBITRUM/LINK-0xf97f4df75117a78c1a5a0dbb814af92458539fb4',
    'BASE/USDC-0x833589fcd6edb6e08f4c7c32d4f71b54bda02913',
    'BASE/USDT-0xfde4c96c8593536e31f229ea8f37b2ada2699bb2',
    'BASE/DAI-0x50c5725949a6f0c72e6c4a641f24049a917db0cb',
    'BASE/WBTC-0x0555e30da8f98308edb960aa94c0db47230d2b9c',
    'BASE/SPX-0x50da645f148798f68ef2d7db7c1cb22a6819bb2c',
    'BASE/WETH-0x4200000000000000000000000000000000000006',
    'BSC/USDC-0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d',
    'BSC/USDE-0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34',
    'BSC/ETH-0x2170ed0880ac9a755fd29b2688956bd959f933f8',
    'BSC/ADA-0x3ee2200efb3400fabb9aacf31297cbdd1d435d47',
    'BSC/PEPE-0x25d887ce7a35172c62febfd67a1856f20faebb00',
    'BSC/WBNB-0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c',
    'POLYGON/DAI-0x8f3cf7ad23cd3cadbd9735aff958023239c6a063',
    'POLYGON/WBTC-0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6',
    'POLYGON/WETH-0x7ceb23fd6bc0add59e62ac25578270cff1b9f619',
    'SOL/BONK-DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263',
    'SOL/RAY-4k3Dyjzvzp8eMZWUXbBCjEvwSkkk59S5iCNLY3QrkX6R',
    'SOL/SOETH-2FPyTwcZLUg1MDrwsyoP4D6s1tM7hAkHYRjkNb5w6Pxk',
    'SOL/BTC-9n4nbM75f5Ui33ZbPYXn59EwSgE8CGsHtAeTH5YFeJ9E',
    'SOL/PYTH-HZ1JovNiVvGrGNiiYvEozEVgZ58xaU3RKwX8eACQBCt3',
    'SOL/GMT-7i5KKsX2weiTkry7jA4ZwSuXGhs5eJBEjY8vVxR4pfRx',
    'SOL/TBB-42cXQvAAr7hcPBPWAS4ocVtDyeJ4Fa6gRR2uG4gppump',
    'SOL/GOOGLX-XsCPL9dNWBMvFtTmwcCA5v3xWPSMEBCszbQdiLLq6aN',
    'SOL/AMZNX-Xs3eBt7uRfJX8QUs4suhyU8p2M6DoUDrJyWBa8LLZsg',
    'SOL/AAPLX-XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp',
    'SOL/CRCLX-XsueG8BtpquVJX9LVLLEGuViXUungE6WmK5YZ3p3bd1',
    'SOL/COINX-Xs7ZdzSHLU9ftNJsii5fCeJhoRWSC32SQGzGQtePxNu',
    'SOL/DFDVX-Xs2yquAgsHByNzx68WJC55WHjHBvG9JsMB7CWjTLyPy',
    'SOL/MCDX-XsqE9cRRpzxcGKDXj1BJ7Xmg4GRhZoyY1KpmGSxAWT2',
    'SOL/METAX-Xsa62P5mvPszXL1krVUnU5ar38bBSVcWAB6fmPCo5Zu',
    'SOL/MSTRX-XsP7xzNPvEHS1m6qfanPUGjNmdnmsLKEoNAnHjdxxyZ',
    'SOL/QQQX-Xs8S1uUs1zvS2p7iwtsG3b6fkhpvmwz4GYU3gWAmWHZ',
    'SOL/NVDAX-Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh',
    'SOL/PGX-XsYdjDjNUygZ7yGKfQaB6TxLh2gC6RRjzLtLAGJrhzV',
    'SOL/SPYX-XsoCS1TfEyfFhfvj8EtZ528L3CaKBDBRqRapnBbDF2W',
    'SOL/TSLAX-XsDoVfqeBukxuZHWhdvWHBhgEHjGNst4MLodqsJHzoB',
    'SOL/UNHX-XszvaiXGPwvk2nwb3o9C1CX4K6zH8sez11E6uyup6fe',
  });

  static const _genericAliases = <String, String>{
    'ape': 'ETH/APE-0x4d224452801aced8b2f0aebe155379bb5d594381',
    'arb': 'ARBITRUM/ARB-0x912ce59144191c1204e64559fe8253a0e49e6548',
    'aave': 'ETH/AAVE-0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9',
    'cake': 'BSC/CAKE-0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82',
    'bat': 'ETH/BAT-0x0d8775f648430679a709e98d2b0cb6250d2887ef',
    'cbbtc': 'ETH/CBBTC-0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf',
    'comp': 'ETH/COMP-0xc00e94cb662c3520282e6f5717214004a7f26888',
    'dydx': 'ETH/DYDX-0x92d6c1e31e14520e676a687f0a93788b716beff5',
    'dai': 'ETH/DAI-0x6b175474e89094c44da98b954eedeac495271d0f',
    'ens': 'ETH/ENS-0xc18360217d8f7ab5e7c516566761ea12ce7f9d72',
    'flip': 'ETH/FLIP-0x826180541412d574cf1336d22c0c0a287822678a',
    'ftm': 'ETH/FTM-0x4e15361fd6b4bb609fa63c81a2be19d873717870',
    'frax': 'ETH/FRAX-0x853d955acef822db058eb8505911ed77f175b99e',
    'grt': 'ETH/GRT-0xc944e90c64b2c07662a292be6244bdf05cda44a7',
    'gusd': 'ETH/GUSD-0x056fd409e1d7a124bd7017459dfea2f387b6d5cd',
    'ldo': 'ETH/LDO-0x5a98fcbea516cf06857215779fd812ca3bef1b32',
    'mana': 'ETH/MANA-0x0f5d2fb29fb7d3cfee444a200298f468908cc942',
    'mkr': 'ETH/MKR-0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2',
    'matic': 'ETH/MATIC-0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0',
    'paxg': 'ETH/PAXG-0x45804880de22913dafe09f4980848ece6ecbaf78',
    'pepe': 'ETH/PEPE-0x6982508145454ce325ddbe47a25d4ec3d2311933',
    'steth': 'ETH/STETH-0xae7ab96520de3a18e5e111b5eaab095312d7fe84',
    'shib': 'ETH/SHIB-0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce',
    'storj': 'ETH/STORJ-0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac',
    'tusd': 'ETH/TUSD-0x0000000000085d4780b73119b644ae5ecd22b376',
    'uni': 'ETH/UNI-0x1f9840a85d5af5bf1d1762f925bdaddc4201f984',
    'zrx': 'ETH/ZRX-0xe41d2489571d322189246dafa5ebde1f4699f498',
    'usdc': 'ETH/USDC-0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
    'usdcsol': 'SOL/USDC-EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
    'usdcpoly': 'POLYGON/USDC-0x3c499c542cef5e3811e1192ce70d8cc03d5c3359',
    'usdcepoly': 'POLYGON/USDC.E-0x2791bca1f2de4661ed88a30c99a7a9449aa84174',
    'usdcarb': 'ARBITRUM/USDC-0xaf88d065e77c8cc2239327c5edb3a432268e5831',
    'usde': 'BASE/USDE-0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34',
    'usdtarb': 'ARBITRUM/USDT-0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9',
    'usdtbsc': 'BSC/USDT-0x55d398326f99059ff775485246999027b3197955',
    'usdterc20': 'ETH/USDT-0xdac17f958d2ee523a2206206994597c13d831ec7',
    'usdtpoly': 'POLYGON/USDT-0xc2132d05d31c914a87c6611c10748aeb04b58e8f',
    'usdtsol': 'SOL/USDT-Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB',
    'wbtc': 'ETH/WBTC-0x2260fac5e5542a773aa44fbcfedf7c193bc2c599',
    'weth': 'ETH/WETH-0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
  };

  static String nativeTokenForChain(String chain) {
    final native = nativeTokenByChain[chain.trim().toUpperCase()];
    if (native == null) throw PegarouteCurrencyException('unknown chain $chain');
    return native;
  }

  PegarouteAssetId map(CryptoCurrency currency) {
    if (currency.name == 'ltcmweb') {
      throw const PegarouteCurrencyException('Litecoin MWEB is not a catalog identity');
    }
    // Explicit token instances must win over title/tag aliases. A token can
    // legitimately share a native ticker (for example a wrapped asset).
    if (currency is Erc20Token) {
      return _evmToken(currency.title, currency.contractAddress, currency.tag, currency.chainId);
    }
    if (currency is SPLToken) return _solanaToken(currency.title, currency.mintAddress);
    if (currency is TronToken) return _tronToken(currency.title, currency.contractAddress);
    if (currency.runtimeType != CryptoCurrency) {
      throw PegarouteCurrencyException('${currency.title}/${currency.tag ?? ''}');
    }

    final tag = currency.tag?.toUpperCase();
    final title = currency.title.toUpperCase();
    final native = _native(tag, title);
    if (native != null) return _catalogAsset(native);

    final alias = _genericAliases[currency.name];
    if (alias != null) {
      final parts = alias.split('/');
      return validateCanonicalTuple(chain: parts[0], token: parts[1],
          nativeToken: nativeTokenForChain(parts[0]));
    }

    throw PegarouteCurrencyException('${currency.title}/${currency.tag ?? ''}');
  }

  bool matchesCanonicalTuple(CryptoCurrency currency, PegarouteAssetId expected) {
    validateCanonicalTuple(
      chain: expected.chain,
      token: expected.token,
      nativeToken: expected.nativeToken,
    );
    try {
      final actual = map(currency);
      return actual.chain == expected.chain &&
          actual.token == expected.token &&
          actual.nativeToken == expected.nativeToken;
    } on PegarouteCurrencyException {
      return false;
    }
  }

  PegarouteAssetId validateCanonicalTuple({
    required String chain,
    required String token,
    required String nativeToken,
  }) {
    return _catalogAsset(PegarouteAssetId(
      chain: chain.trim().toUpperCase(),
      token: token,
      nativeToken: nativeToken,
    ));
  }

  PegarouteAssetId? _native(String? tag, String title) {
    if (tag == 'ARB' && title == 'ETH')
      return const PegarouteAssetId(chain: 'ARBITRUM', token: 'ETH', nativeToken: 'ETH');
    if (tag == 'AVAXC' && title == 'AVAX')
      return const PegarouteAssetId(chain: 'AVAX', token: 'AVAX', nativeToken: 'AVAX');
    if (tag == 'POL' && title == 'POL')
      return const PegarouteAssetId(chain: 'POLYGON', token: 'POL', nativeToken: 'POL');
    if (title == 'TRX' && (tag == null || tag == 'TRX'))
      return const PegarouteAssetId(chain: 'TRON', token: 'TRX', nativeToken: 'TRX');
    if (title == 'ADA' && (tag == null || tag == 'ADA' || tag == 'CARDANO'))
      return const PegarouteAssetId(chain: 'CARDANO', token: 'ADA', nativeToken: 'ADA');
    if (title == 'XRP' && (tag == null || tag == 'XRP'))
      return const PegarouteAssetId(chain: 'XRP', token: 'XRP', nativeToken: 'XRP');
    if (tag == 'BSC' && title == 'BNB')
      return const PegarouteAssetId(chain: 'BSC', token: 'BNB', nativeToken: 'BNB');
    if (tag == 'BASE' && title == 'ETH')
      return const PegarouteAssetId(chain: 'BASE', token: 'ETH', nativeToken: 'ETH');
    if (title == 'ETH' && (tag == null || tag == 'ETH'))
      return const PegarouteAssetId(chain: 'ETH', token: 'ETH', nativeToken: 'ETH');
    if (title == 'SOL' && (tag == null || tag == 'SOL'))
      return const PegarouteAssetId(chain: 'SOL', token: 'SOL', nativeToken: 'SOL');
    if (title == 'XLM' && (tag == null || tag == 'STELLAR'))
      return const PegarouteAssetId(chain: 'STELLAR', token: 'XLM', nativeToken: 'XLM');
    if (title == 'RUNE' && (tag == null || tag == 'THOR'))
      return const PegarouteAssetId(chain: 'THOR', token: 'RUNE', nativeToken: 'RUNE');

    const nativeChains = {'XMR', 'BTC', 'BCH', 'LTC', 'DOGE', 'DASH', 'ZEC'};
    if (nativeChains.contains(title) && (tag == null || tag == title)) {
      return PegarouteAssetId(chain: title, token: title, nativeToken: title);
    }
    if ((title == 'TZEC' || title == 'ZZEC') && tag == 'ZEC') {
      return const PegarouteAssetId(chain: 'ZEC', token: 'ZEC', nativeToken: 'ZEC');
    }
    return null;
  }

  PegarouteAssetId _evmToken(String symbol, String contract, String? tag, int? chainId) {
    if (!RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(contract)) {
      throw const PegarouteCurrencyException('invalid EVM contract');
    }
    final chain = _chainFromTagOrId(tag, chainId);
    final asset = PegarouteAssetId(
      chain: chain,
      token: '${symbol.toUpperCase()}-${contract.toLowerCase()}',
      nativeToken: nativeTokenForChain(chain),
    );
    return _catalogAsset(asset);
  }

  PegarouteAssetId _solanaToken(String symbol, String mint) {
    if (mint.isEmpty) throw const PegarouteCurrencyException('missing Solana mint');
    return _catalogAsset(PegarouteAssetId(
      chain: 'SOL',
      token: '${symbol.toUpperCase()}-$mint',
      nativeToken: 'SOL',
    ));
  }

  PegarouteAssetId _tronToken(String symbol, String contract) {
    if (contract.isEmpty) throw const PegarouteCurrencyException('missing TRON contract');
    return _catalogAsset(PegarouteAssetId(
      chain: 'TRON',
      token: '${symbol.toUpperCase()}-$contract',
      nativeToken: 'TRX',
    ));
  }

  String _chainFromTagOrId(String? tag, int? chainId) {
    const ids = {
      1: 'ETH',
      56: 'BSC',
      137: 'POLYGON',
      43114: 'AVAX',
      42161: 'ARBITRUM',
      8453: 'BASE'
    };
    final byId = chainId == null ? null : ids[chainId];
    if (chainId != null && byId == null) {
      throw const PegarouteCurrencyException('unknown EVM chain id');
    }
    final normalizedTag = tag?.toUpperCase();
    if (tag != null && !_chainAliases.containsKey(normalizedTag)) {
      throw const PegarouteCurrencyException('unknown EVM chain tag');
    }
    final byTag = _chainAliases[normalizedTag];
    if (byId != null && byTag != null && byId != byTag) {
      throw const PegarouteCurrencyException('conflicting chain tag and chain id');
    }
    final chain = byId ?? byTag;
    if (chain == null) throw const PegarouteCurrencyException('missing EVM chain identity');
    return chain;
  }

  PegarouteAssetId _catalogAsset(PegarouteAssetId asset) {
    _validateCanonicalTuple(asset);
    if (!_catalogAssets.contains('${asset.chain}/${asset.token}')) {
      throw PegarouteCurrencyException(
          '${asset.chain}/${asset.token} is not in the Pegasus catalog');
    }
    return asset;
  }

  void _validateCanonicalTuple(PegarouteAssetId asset) {
    if (nativeTokenByChain[asset.chain] != asset.nativeToken || asset.token.isEmpty) {
      throw const PegarouteCurrencyException('invalid canonical asset tuple');
    }
    final separator = asset.token.indexOf('-');
    if (separator == 0 || separator == asset.token.length - 1) {
      throw const PegarouteCurrencyException('invalid qualified token');
    }
    if (separator >= 0 &&
        const {'ETH', 'BSC', 'POLYGON', 'AVAX', 'ARBITRUM', 'BASE'}.contains(asset.chain) &&
        !RegExp(r'^0x[0-9a-f]{40}$').hasMatch(asset.token.substring(separator + 1))) {
      throw const PegarouteCurrencyException('invalid qualified EVM token');
    }
  }

  static const _chainAliases = {
    'ARB': 'ARBITRUM',
    'ARBITRUM': 'ARBITRUM',
    'AVAXC': 'AVAX',
    'AVAX': 'AVAX',
    'POL': 'POLYGON',
    'POLYGON': 'POLYGON',
    'ETH': 'ETH',
    'BSC': 'BSC',
    'BASE': 'BASE',
  };
}
