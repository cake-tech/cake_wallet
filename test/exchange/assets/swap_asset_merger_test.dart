import "package:cake_wallet/exchange/assets/provider_asset_index.dart";
import "package:cake_wallet/exchange/assets/provider_listing.dart";
import "package:cake_wallet/exchange/assets/swap_asset_merger.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/swap_networks.dart";
import "package:flutter_test/flutter_test.dart";

const _pepe = "0x6982508145454Ce325dDbE47a25d4ec3d2311933";
const _usdt = "0xdAC17F958D2ee523a2206206994597C13D831ec7";

const _changeNow = ExchangeProviderDescription.changeNow;
const _swapsXyz = ExchangeProviderDescription.swapsXyz;
const _trocador = ExchangeProviderDescription.trocador;

ProviderListing _listing(
  ExchangeProviderDescription provider,
  String tag,
  String ticker, {
  String? contract,
  String network = "net",
  bool isNative = false,
  String? iconUrl,
  String? fullName,
  bool isStock = false,
}) => ProviderListing(
  provider: provider,
  tag: tag,
  ticker: ticker,
  network: network,
  contractAddress: contract,
  iconUrl: iconUrl,
  fullName: fullName,
  isNative: isNative,
  isStock: isStock,
);

void main() {
  group("mergeListings", () {
    test("the same contract from two providers is one asset named by the first", () {
      final assets = mergeListings([
        _listing(_swapsXyz, "ETH", "PEPE", contract: _pepe.toLowerCase(), network: "1"),
        _listing(_changeNow, "ETH", "pepe", contract: _pepe, iconUrl: "pepe.png", fullName: "Pepe"),
      ]);

      final pepe = assets.single;
      expect(pepe.assetKey, "ETH/${_pepe.toLowerCase()}");
      expect(pepe.title, "PEPE");
      expect(pepe.contractAddress, _pepe.toLowerCase());
      expect(pepe.iconUrl, "pepe.png");
      expect(pepe.fullName, "Pepe");
      expect(pepe.listings.map((listing) => listing.provider), [_swapsXyz, _changeNow]);
    });

    test("native coins are one asset per chain whatever the providers call them", () {
      final assets = mergeListings([
        _listing(_swapsXyz, "ARB", "ETH", isNative: true),
        _listing(_changeNow, "ARB", "ARBETH"),
      ]);

      expect(assets.single.assetKey, "ARB/native");
      expect(assets.single.title, "ETH");
      expect(assets.single.listings, hasLength(2));
    });

    test("a listing without a contract joins the only asset with its title", () {
      final assets = mergeListings([
        _listing(_trocador, "ETH", "pepe", network: "ERC20"),
        _listing(_swapsXyz, "ETH", "PEPE", contract: _pepe),
      ]);

      expect(assets.single.assetKey, "ETH/${_pepe.toLowerCase()}");
      expect(assets.single.listings.map((listing) => listing.provider), [_swapsXyz, _trocador]);
    });

    test("a listing without a contract is left out when its title is ambiguous", () {
      final assets = mergeListings([
        _listing(_swapsXyz, "TRX", "USDD", contract: "TPYmHEhy5n8TCEfYGqW2rPxsghSfzghPDn"),
        _listing(_swapsXyz, "TRX", "USDD", contract: "TXDk8mbtRbXeYuMNS83CfKPaYYT8XWv9Hz"),
        _listing(_trocador, "TRX", "usdd", network: "TRC20"),
      ]);

      expect(assets, hasLength(2));
      expect(assets.expand((asset) => asset.listings).map((listing) => listing.provider), [
        _swapsXyz,
        _swapsXyz,
      ]);
    });

    test("listings of a title nobody has a contract for are one asset", () {
      final assets = mergeListings([
        _listing(_trocador, "BSC", "foo", network: "BEP20"),
        _listing(_changeNow, "BSC", "FOO", network: "bsc"),
      ]);

      expect(assets.single.assetKey, "BSC/symbol:FOO");
      expect(assets.single.hasContract, isFalse);
      expect(assets.single.listings, hasLength(2));
    });

    test("an asset is a stock when any provider says so", () {
      const mint = "Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh";
      final assets = mergeListings([
        _listing(_changeNow, "SOL", "nvdax", contract: mint),
        _listing(_swapsXyz, "SOL", "NVDAx", contract: mint, isStock: true),
      ]);

      expect(assets.single.isStock, isTrue);
    });
  });

  group("ProviderAssetIndex", () {
    test("the ARB token is keyed by its contract, apart from Arbitrum's ETH", () {
      const arb = "0x912ce59144191c1204e64559fe8253a0e49e6548";
      final index = ProviderAssetIndex()
        ..update(
          rows: const [],
          tokens: [
            Erc20Token(
              name: "Arbitrum",
              symbol: "ARB",
              contractAddress: arb,
              decimal: 18,
              tag: "ARB",
            ),
          ],
        );

      expect(index.keyOf(CryptoCurrency.arb), "ARB/$arb");
      expect(index.keyOf(CryptoCurrency.arbEth), "ARB/native");
      expect(index.keyOf(CryptoCurrency.btcln), "LN/native");
      expect(index.keyOf(CryptoCurrency.bnb), "BSC/native");
    });
  });

  group("SwapNetworks", () {
    test("maps the providers' network names onto Cake's tags", () {
      expect(SwapNetworks.tagFor("BNB Smart Chain"), "BSC");
      expect(SwapNetworks.tagFor("bep20"), "BSC");
      expect(SwapNetworks.tagFor("ethereumarbone"), "ARB");
      expect(SwapNetworks.tagFor("cchain"), "AVAXC");
      expect(SwapNetworks.tagFor("matic"), "POL");
      expect(SwapNetworks.tagFor("LIGHTNING"), "LN");
      expect(SwapNetworks.tagFor("assethub"), "DOT");
      expect(SwapNetworks.tagFor("World Mobile"), "WORLDMOBILE");
    });

    test("knows each chain's native tickers", () {
      expect(SwapNetworks.isNativeTicker("ARB", "arbeth"), isTrue);
      expect(SwapNetworks.isNativeTicker("ARB", "ARB"), isFalse);
      expect(SwapNetworks.isNativeTicker("TON", "GRAM"), isTrue);
      expect(SwapNetworks.isNativeTicker("BTC", "btc"), isTrue);
      expect(SwapNetworks.nativeTitle("ARB"), "ETH");
      expect(SwapNetworks.nativeTitle("SUI"), "SUI");
      expect(SwapNetworks.isTestnet("Base Sepolia"), isTrue);
      expect(SwapNetworks.isTestnet("Base"), isFalse);
    });
  });

  group("ProviderListing", () {
    test("keys natives by chain, EVM contracts lowercased and other contracts as they are", () {
      expect(_listing(_changeNow, "ARB", "ARBETH").assetKey, "ARB/native");
      expect(_listing(_changeNow, "ARB", "ARBETH").title, "ETH");
      expect(
        _listing(_changeNow, "ETH", "usdt", contract: _usdt).assetKey,
        "ETH/${_usdt.toLowerCase()}",
      );
      expect(
        _listing(
          _changeNow,
          "SOL",
          "BONK",
          contract: "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",
        ).assetKey,
        "SOL/DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",
      );
      expect(_listing(_changeNow, "THETA", "tfuel").assetKey, "THETA/symbol:TFUEL");
      expect(_listing(_changeNow, "ETH", "x", iconUrl: " ").iconUrl, isNull);
    });
  });
}
