import "dart:io";

import "package:cake_wallet/exchange/evm_provider_network_codes.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/changenow_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/swapsxyz_exchange_provider.dart";
import "package:cake_wallet/exchange/provider/xoswap_exchange_provider.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/abstract.dart";
import "package:cw_core/utils/tor/disabled.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mocktail/mocktail.dart";

class _MockSettingsStore extends Mock implements SettingsStore {}

// Records the URL and fails the request, so nothing reaches the provider
class _RecordingHttpClient extends Fake implements HttpClient {
  final urls = <Uri>[];

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    urls.add(url);
    throw const SocketException("blocked in test");
  }

  @override
  void close({bool force = false}) {}
}

CryptoCurrency _addedNative(int chainId, String title) => CryptoCurrency(
      title: title,
      tag: "$title-$chainId",
      name: "evm$chainId",
      raw: EvmNativeCurrencies.addedNetworkRawOffset + chainId,
      decimals: 18,
    );

void main() {
  // Ink, because ChangeNow lists no Ink network while Swaps.xyz does
  const inkChainId = 57073;
  // OP Mainnet, where ChangeNow does list a network
  const opChainId = 10;
  // Avalanche C-Chain, an A-Z network whose AVAX the providers already trade as avaxc
  const avalancheChainId = 43114;

  const inkNative = CryptoCurrency(
    title: "ETH",
    tag: "INK",
    name: "evm$inkChainId",
    raw: EvmNativeCurrencies.addedNetworkRawOffset + inkChainId,
    decimals: 18,
  );

  const opNative = CryptoCurrency(
    title: "ETH",
    tag: "OETH",
    name: "evm$opChainId",
    raw: EvmNativeCurrencies.addedNetworkRawOffset + opChainId,
    decimals: 18,
  );

  // ChainList's short name "avax" clashes with CryptoCurrency.avaxc's title, so the tag gets the ID
  const avalancheNative = CryptoCurrency(
    title: "AVAX",
    tag: "AVAX-$avalancheChainId",
    name: "evm$avalancheChainId",
    raw: EvmNativeCurrencies.addedNetworkRawOffset + avalancheChainId,
    decimals: 18,
  );

  final inkUsdc = Erc20Token(
    name: "USD Coin",
    symbol: "USDC",
    contractAddress: "0x2d270e6886d130d724215a266106e6832161eaed",
    decimal: 6,
    chainId: inkChainId,
  );

  final ethereumUsdc = Erc20Token(
    name: "USD Coin",
    symbol: "USDC",
    contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    decimal: 6,
    chainId: 1,
  );

  setUp(() {
    EvmNativeCurrencies.register(inkChainId, inkNative, WalletType.evm);
    EvmNativeCurrencies.register(opChainId, opNative, WalletType.evm);
    EvmNativeCurrencies.register(avalancheChainId, avalancheNative, WalletType.evm);
  });

  tearDown(() {
    EvmNativeCurrencies.unregister(inkChainId);
    EvmNativeCurrencies.unregister(opChainId);
    EvmNativeCurrencies.unregister(avalancheChainId);
  });

  group("evmExchangeProviderNetworkCode", () {
    test("a token on an added network without a ChangeNow code is refused by ChangeNow", () {
      expect(EvmNativeCurrencies.isAddedNetworkCurrency(inkUsdc), isTrue);
      expect(isCurrencyNetworkSupported(inkUsdc, ExchangeProviderDescription.changeNow), isFalse);
      expect(
        () => evmExchangeProviderNetworkCode(inkUsdc, ExchangeProviderDescription.changeNow),
        throwsException,
      );
    });

    test("Swaps.xyz and XOSwap take any added network, matching it by chain ID on their own lists",
        () {
      expect(isCurrencyNetworkSupported(inkUsdc, ExchangeProviderDescription.swapsXyz), isFalse);
      expect(isCurrencyNetworkSupported(inkUsdc, ExchangeProviderDescription.xoSwap), isFalse);

      expect(SwapsXyzExchangeProvider().supportsCurrencyNetwork(inkUsdc), isTrue);
      expect(XOSwapExchangeProvider().supportsCurrencyNetwork(inkUsdc), isTrue);
    });

    test("a provider that names chains follows the table", () {
      final changeNow = ChangeNowExchangeProvider(settingsStore: _MockSettingsStore());

      expect(changeNow.supportsCurrencyNetwork(inkUsdc), isFalse);
      expect(changeNow.supportsCurrencyNetwork(opNative), isTrue);
      expect(changeNow.supportsCurrencyNetwork(CryptoCurrency.eth), isTrue);
    });

    test("an added network's native resolves to the provider's documented code", () {
      expect(evmExchangeProviderNetworkCode(opNative, ExchangeProviderDescription.changeNow), "op");
      expect(
        evmExchangeProviderNetworkCode(opNative, ExchangeProviderDescription.exolix),
        "OPTIMISM",
      );
    });

    test("currencies with no chain or on a built-in chain keep their existing path", () {
      for (final currency in <CryptoCurrency>[
        CryptoCurrency.usdterc20,
        CryptoCurrency.avaxc,
        CryptoCurrency.eth,
        ethereumUsdc,
      ]) {
        expect(
          EvmNativeCurrencies.isAddedNetworkCurrency(currency),
          isFalse,
          reason: currency.title,
        );
        expect(
          isCurrencyNetworkSupported(currency, ExchangeProviderDescription.changeNow),
          isTrue,
          reason: currency.title,
        );
        expect(
          evmExchangeProviderNetworkCode(currency, ExchangeProviderDescription.swapsXyz),
          isNull,
          reason: currency.title,
        );
      }
    });

    test("an added network's ETH on chain 10 counts as added, Ethereum's ETH does not", () {
      expect(opNative.title, CryptoCurrency.eth.title);
      expect(EvmNativeCurrencies.isAddedNetworkCurrency(opNative), isTrue);
      expect(EvmNativeCurrencies.isAddedNetworkCurrency(CryptoCurrency.eth), isFalse);
    });

    test("AVAX on an added Avalanche network gets the codes the providers send for avaxc", () {
      expect(
        evmExchangeProviderNetworkCode(avalancheNative, ExchangeProviderDescription.changeNow),
        "cchain",
      );
      expect(
        evmExchangeProviderNetworkCode(avalancheNative, ExchangeProviderDescription.exolix),
        "AVAXC",
      );
      expect(
        evmExchangeProviderNetworkCode(avalancheNative, ExchangeProviderDescription.nearIntents),
        "avax",
      );
      expect(
        evmExchangeProviderNetworkCode(avalancheNative, ExchangeProviderDescription.sideShift),
        "avax",
      );
    });

    test("a provider with no Avalanche code of its own is refused for the added AVAX", () {
      expect(
        isCurrencyNetworkSupported(avalancheNative, ExchangeProviderDescription.trocador),
        isFalse,
      );
      expect(
        () => evmExchangeProviderNetworkCode(avalancheNative, ExchangeProviderDescription.trocador),
        throwsException,
      );
    });

    test("the const avaxc keeps its own path", () {
      expect(EvmNativeCurrencies.isAddedNetworkCurrency(CryptoCurrency.avaxc), isFalse);
      expect(
        evmExchangeProviderNetworkCode(
          CryptoCurrency.avaxc,
          ExchangeProviderDescription.changeNow,
        ),
        isNull,
      );
    });

    test("a token whose added network is not registered still counts as added", () {
      EvmNativeCurrencies.unregister(inkChainId);

      expect(EvmNativeCurrencies.isAddedNetworkCurrency(inkUsdc), isTrue);
      expect(isCurrencyNetworkSupported(inkUsdc, ExchangeProviderDescription.changeNow), isFalse);
    });

    test("each native gets the code read from the provider's own list", () {
      final cells = <(int, String, ExchangeProviderDescription, String)>[
        (10, "ETH", ExchangeProviderDescription.letsExchange, "OPTIMISM"),
        (10, "ETH", ExchangeProviderDescription.nearIntents, "op"),
        (999, "HYPE", ExchangeProviderDescription.letsExchange, "HYPEEVM"),
        (143, "MON", ExchangeProviderDescription.letsExchange, "MONAD"),
        (143, "MON", ExchangeProviderDescription.nearIntents, "monad"),
        (9745, "XPL", ExchangeProviderDescription.letsExchange, "XPL"),
        (9745, "XPL", ExchangeProviderDescription.nearIntents, "plasma"),
        (196, "OKB", ExchangeProviderDescription.nearIntents, "xlayer"),
        (25, "CRO", ExchangeProviderDescription.letsExchange, "CROEVM"),
        (25, "CRO", ExchangeProviderDescription.sideShift, "cronos"),
        (43114, "AVAX", ExchangeProviderDescription.letsExchange, "AVAXC"),
        (43114, "AVAX", ExchangeProviderDescription.thorChain, "AVAX"),
      ];

      for (final (chainId, title, provider, code) in cells) {
        final native = _addedNative(chainId, title);
        final reason = "${provider.title} on $chainId";

        expect(isCurrencyNetworkSupported(native, provider), isTrue, reason: reason);
        expect(evmExchangeProviderNetworkCode(native, provider), code, reason: reason);
      }
    });

    test("natives a provider lists but cannot pay out as the native are refused", () {
      final cells = <(int, String, ExchangeProviderDescription)>[
        (196, "OKB", ExchangeProviderDescription.changeNow),
        (143, "MON", ExchangeProviderDescription.exolix),
      ];

      for (final (chainId, title, provider) in cells) {
        final native = _addedNative(chainId, title);
        final reason = "${provider.title} on $chainId";

        expect(isCurrencyNetworkSupported(native, provider), isFalse, reason: reason);
        expect(
          () => evmExchangeProviderNetworkCode(native, provider),
          throwsException,
          reason: reason,
        );
      }
    });
  });

  group("ChangeNow on Monad", () {
    const monadChainId = 143;

    final monadNative = _addedNative(monadChainId, "MON");

    final monadUsdc = Erc20Token(
      name: "USD Coin",
      symbol: "USDC",
      contractAddress: "0x754704bc059f8c67012fed69bc8a327a5aafb603",
      decimal: 6,
      chainId: monadChainId,
    );

    CakeTorInstance? previousTor;
    late _RecordingHttpClient client;
    late ChangeNowExchangeProvider changeNow;

    setUp(() {
      previousTor = CakeTor.instance;
      CakeTor.instance = CakeTorDisabled();
      client = _RecordingHttpClient();
      changeNow = ChangeNowExchangeProvider(settingsStore: _MockSettingsStore());
    });

    tearDown(() => CakeTor.instance = previousTor);

    Future<Map<String, String>> rangeQueryFor(CryptoCurrency from, CryptoCurrency to) async {
      await HttpOverrides.runZoned(
        () => expectLater(
          changeNow.fetchLimits(from: from, to: to, isFixedRateMode: false),
          throwsA(isA<SocketException>()),
        ),
        createHttpClient: (_) => client,
      );

      return client.urls.single.queryParameters;
    }

    test("native MON is asked for as monad on the mon network", () async {
      final query = await rangeQueryFor(monadNative, CryptoCurrency.btc);

      expect(query["fromCurrency"], "monad");
      expect(query["fromNetwork"], "mon");
      expect(query["toCurrency"], "btc");
    });

    test("a token on Monad keeps its own ticker", () async {
      final query = await rangeQueryFor(monadUsdc, CryptoCurrency.eth);

      expect(query["fromCurrency"], "usdc");
      expect(query["fromNetwork"], "mon");
    });
  });
}
