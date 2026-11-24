/// A chain as Cake tags it, with the names swap providers use for it and its native tickers.
class SwapNetwork {
  const SwapNetwork(this.tag, {this.aliases = const [], this.natives = const []});

  final String tag;

  /// Lowercase network ids and chain names used by the providers
  final List<String> aliases;

  /// Tickers the providers use for the chain's native coin, the first one being Cake's.
  /// Empty when the native coin is called like the tag
  final List<String> natives;
}

abstract final class SwapNetworks {
  static const _ethL2 = ["ETH"];

  static const all = <SwapNetwork>[
    SwapNetwork("ETH", aliases: ["ethereum", "erc20", "ethereum mainnet"]),
    SwapNetwork(
      "BSC",
      aliases: ["bep20", "bnb smart chain", "binance smart chain", "bnb chain"],
      natives: ["BNB"],
    ),
    SwapNetwork(
      "POL",
      aliases: ["matic", "polygon", "poly", "polygon pos"],
      natives: ["POL", "MATIC"],
    ),
    SwapNetwork("TRX", aliases: ["tron", "trc20"]),
    SwapNetwork("SOL", aliases: ["solana", "spl"]),
    SwapNetwork("BASE", aliases: ["basemainnet", "base mainnet"], natives: _ethL2),
    SwapNetwork(
      "ARB",
      aliases: ["arbitrum", "arbitrum one", "ethereumarbone"],
      natives: ["ETH", "ARBETH"],
    ),
    SwapNetwork("OP", aliases: ["optimism", "op mainnet"], natives: _ethL2),
    SwapNetwork(
      "AVAXC",
      aliases: ["cchain", "avax", "avalanche", "avalanche c-chain", "c-chain"],
      natives: ["AVAX"],
    ),
    SwapNetwork("ROB", aliases: ["hood", "robinhood", "robinhood chain"], natives: _ethL2),
    SwapNetwork("LN", aliases: ["lightning"], natives: ["BTC"]),
    SwapNetwork("ZKSYNC", aliases: ["zksync era"], natives: _ethL2),
    SwapNetwork("LINEA", aliases: ["lna"], natives: _ethL2),
    SwapNetwork("SCROLL", natives: _ethL2),
    SwapNetwork("BLAST", natives: _ethL2),
    SwapNetwork("ABS", aliases: ["abstract"], natives: _ethL2),
    SwapNetwork("MEGAETH", natives: _ethL2),
    SwapNetwork("UNICHAIN", natives: _ethL2),
    SwapNetwork("MANTA", aliases: ["manta pacific"], natives: _ethL2),
    SwapNetwork("WORLDCHAIN", aliases: ["world chain"], natives: _ethL2),
    SwapNetwork("ZORA", natives: _ethL2),
    SwapNetwork("INK", natives: _ethL2),
    SwapNetwork("MODE", natives: _ethL2),
    SwapNetwork("LISK", natives: _ethL2),
    SwapNetwork("SONEIUM", natives: _ethL2),
    SwapNetwork("MNT", aliases: ["mantle"]),
    SwapNetwork("CRO", aliases: ["cronos", "croevm", "cronos evm"]),
    SwapNetwork("GNOSIS", aliases: ["xdai", "gnosis chain"], natives: ["XDAI"]),
    SwapNetwork("CELO"),
    SwapNetwork("SONIC", natives: ["S"]),
    SwapNetwork("MON", aliases: ["monad"], natives: ["MON", "MONAD"]),
    SwapNetwork("BERA", aliases: ["berachain"]),
    SwapNetwork("HYPEREVM", aliases: ["hype evm"], natives: ["HYPE"]),
    SwapNetwork("HYPERCORE", natives: ["HYPE"]),
    SwapNetwork("SEI", aliases: ["seievm", "sei evm"]),
    SwapNetwork("XPL", aliases: ["plasma"]),
    SwapNetwork("XLAYER", aliases: ["x layer"], natives: ["OKB"]),
    SwapNetwork("OPBNB", natives: ["BNB"]),
    SwapNetwork("KAIA", aliases: ["klay", "klaytn"], natives: ["KAIA", "KLAY"]),
    SwapNetwork("PLS", aliases: ["pulse", "pulsechain"]),
    SwapNetwork("FTM", aliases: ["fantom"]),
    SwapNetwork("STRK", aliases: ["starknet"]),
    SwapNetwork("APT", aliases: ["aptos"]),
    SwapNetwork("SUI"),
    SwapNetwork("TON", aliases: ["toncoin"], natives: ["TON", "GRAM"]),
    SwapNetwork("NEAR", natives: ["NEAR", "WNEAR"]),
    SwapNetwork("ADA", aliases: ["cardano"]),
    SwapNetwork("XLM", aliases: ["stellar"]),
    SwapNetwork("XRP", aliases: ["ripple"]),
    SwapNetwork("BTC", aliases: ["bitcoin"]),
    SwapNetwork("LTC", aliases: ["litecoin"]),
    SwapNetwork("DOGE", aliases: ["dogecoin"]),
    SwapNetwork("BCH", aliases: ["bitcoin cash", "bitcoincash", "bcash"]),
    SwapNetwork("ZEC", aliases: ["zcash"]),
    SwapNetwork("XMR", aliases: ["monero"]),
    SwapNetwork("DOT", aliases: ["polkadot", "assethub", "asset hub", "hub"]),
    SwapNetwork("ALGO", aliases: ["algorand"]),
    SwapNetwork("ATOM", aliases: ["cosmos"]),
    SwapNetwork("KAS", aliases: ["kaspa"]),
    SwapNetwork("HBAR", aliases: ["hedera"]),
    SwapNetwork("VET", aliases: ["vechain"]),
    SwapNetwork("EGLD", aliases: ["multiversx", "elrond"]),
    SwapNetwork("ETC", aliases: ["ethereum classic"]),
    SwapNetwork("EOS", aliases: ["eosio"]),
    SwapNetwork("NEO", aliases: ["neo3"]),
    SwapNetwork("CHZ", aliases: ["chiliz"]),
    SwapNetwork("FIL", aliases: ["filecoin"]),
    SwapNetwork("XTZ", aliases: ["tezos"]),
    SwapNetwork("BSV", aliases: ["bitcoinsv"]),
    SwapNetwork("AKT", aliases: ["akash"]),
    SwapNetwork("BABY", aliases: ["babylon"]),
    SwapNetwork("RON", aliases: ["ronin"]),
  ];

  static final Map<String, SwapNetwork> _byAlias = {
    for (final network in all) ...{
      network.tag.toLowerCase(): network,
      for (final alias in network.aliases) alias: network,
    },
  };

  static final _nonAlphanumeric = RegExp("[^A-Z0-9]");

  static final _testnet = RegExp("testnet|sepolia|devnet|amoy|holesky|fuji", caseSensitive: false);

  static String tagFor(String network) =>
      _byAlias[network.trim().toLowerCase()]?.tag ??
      network.toUpperCase().replaceAll(_nonAlphanumeric, "");

  static bool isTestnet(String network) => _testnet.hasMatch(network);

  static bool isNativeTicker(String tag, String ticker) => switch (_byAlias[tag.toLowerCase()]) {
    SwapNetwork(:final natives) when natives.isNotEmpty => natives.contains(ticker.toUpperCase()),
    _ => ticker.toUpperCase() == tag,
  };

  static String nativeTitle(String tag) => switch (_byAlias[tag.toLowerCase()]) {
    SwapNetwork(:final natives) when natives.isNotEmpty => natives.first,
    _ => tag,
  };
}
