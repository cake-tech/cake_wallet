import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/evm_network.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const addedChainId = 999;
  const otherChainId = 998;

  const addedNative = CryptoCurrency(
    title: "XYZ",
    tag: "XYZNET",
    name: "evm$addedChainId",
    raw: EvmNativeCurrencies.addedNetworkRawOffset + addedChainId,
    decimals: 18,
  );

  WalletInfo walletInfo(WalletType type, {int? chainId}) => WalletInfo.external(
        id: "${type.name}_$chainId",
        name: "${type.name}_$chainId",
        type: type,
        isRecovery: false,
        restoreHeight: 0,
        date: DateTime(2026),
        dirPath: "",
        path: "",
        address: "",
        chainId: chainId,
      );

  setUp(() => EvmNativeCurrencies.register(addedChainId, addedNative, WalletType.evm));

  tearDown(() => EvmNativeCurrencies.unregister(addedChainId));

  group("EvmNativeCurrencies", () {
    test("getChainIdByCryptoCurrency answers from a token's own chain, the table, or not at all",
        () {
      expect(getChainIdByCryptoCurrency(addedNative), addedChainId);

      final baseUsdc = Erc20Token(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
        decimal: 6,
        chainId: 8453,
      );
      expect(getChainIdByCryptoCurrency(baseUsdc), 8453);

      final unsavedTemplate = Erc20Token(
        name: "Tether USD",
        symbol: "USDT",
        contractAddress: "0xdac17f958d2ee523a2206206994597c13d831ec7",
        decimal: 6,
      );
      expect(getChainIdByCryptoCurrency(unsavedTemplate), isNull);

      expect(getChainIdByCryptoCurrency(CryptoCurrency.avaxc), isNull);
    });

    test("an offset raw deserializes to the registered instance only", () {
      expect(
        identical(
          CryptoCurrency.deserialize(raw: EvmNativeCurrencies.addedNetworkRaw(addedChainId)),
          addedNative,
        ),
        isTrue,
      );

      // Chain 1's native keeps its own raw, so addedNetworkRaw(1) decodes to nothing
      expect(
        () => CryptoCurrency.deserialize(raw: EvmNativeCurrencies.addedNetworkRaw(1)),
        throwsArgumentError,
      );
    });

    test("isWalletForCurrency matches an evm wallet by chain ID", () {
      expect(
        EvmNativeCurrencies.isWalletForCurrency(
          walletInfo(WalletType.evm, chainId: addedChainId),
          addedNative,
        ),
        isTrue,
      );
      expect(
        EvmNativeCurrencies.isWalletForCurrency(
          walletInfo(WalletType.evm, chainId: otherChainId),
          addedNative,
        ),
        isFalse,
      );
      expect(
        EvmNativeCurrencies.isWalletForCurrency(walletInfo(WalletType.ethereum), addedNative),
        isFalse,
      );
      expect(
        EvmNativeCurrencies.isWalletForCurrency(
          walletInfo(WalletType.ethereum),
          CryptoCurrency.eth,
        ),
        isTrue,
      );
    });

    test("wallet type resolution keeps today's answers for const currencies", () {
      expect(cryptoCurrencyOrTokenToWalletType(addedNative), WalletType.evm);
      expect(cryptoCurrencyOrTokenToWalletType(CryptoCurrency.bnb), WalletType.bsc);
      // CRO is an Ethereum token (tag ETH), so the tag match resolves it
      expect(cryptoCurrencyOrTokenToWalletType(CryptoCurrency.cro), WalletType.ethereum);
    });

    group("an added network that looks like another chain", () {
      // A manual network the user named BSC, with BNB Smart Chain's symbol and decimals
      const lookalikeChainId = 777;
      const firstLongChainId = 1001;
      const secondLongChainId = 1002;

      EvmNetwork network(int chainId, String name, String symbol, String tag) => EvmNetwork(
            chainId: chainId,
            name: name,
            symbol: symbol,
            decimals: 18,
            tag: tag,
            rpcUrl: "https://rpc.example",
          );

      tearDown(() {
        EvmNativeCurrencies.unregister(lookalikeChainId);
        EvmNativeCurrencies.unregister(firstLongChainId);
        EvmNativeCurrencies.unregister(secondLongChainId);
      });

      test("a BSC tag takes its chain ID and the native resolves to its own chain", () {
        final lookalike = network(lookalikeChainId, "BSC", "BNB", "BSC").withUniqueTag(const []);
        final currency = AddedNetworkCurrency(lookalike);
        EvmNativeCurrencies.register(lookalikeChainId, currency, WalletType.evm);

        expect(lookalike.tag, "BSC-777");
        expect(currency == CryptoCurrency.bnb, isFalse);
        expect(CryptoCurrency.bnb == currency, isFalse);
        expect(getChainIdByCryptoCurrency(currency), lookalikeChainId);
        expect(getChainIdByCryptoCurrency(CryptoCurrency.bnb), 56);
        expect(cryptoCurrencyOrTokenToWalletType(currency), WalletType.evm);
      });

      test("a copy of an added native still resolves to its chain through its raw", () {
        final currency = AddedNetworkCurrency(
          network(lookalikeChainId, "BSC", "BNB", "BSC").withUniqueTag(const []),
        );
        EvmNativeCurrencies.register(lookalikeChainId, currency, WalletType.evm);

        expect(getChainIdByCryptoCurrency(currency.copyWith()), lookalikeChainId);
      });

      test("two networks with the same tag prefix and symbol stay distinct", () {
        final first = network(firstLongChainId, "Longnetwork One", "LNW", "LONGNETWOR");
        final second = network(secondLongChainId, "Longnetwork Two", "LNW", "LONGNETWOR")
            .withUniqueTag([first]);
        final firstCurrency = AddedNetworkCurrency(first.withUniqueTag([second]));
        final secondCurrency = AddedNetworkCurrency(second);
        EvmNativeCurrencies.register(firstLongChainId, firstCurrency, WalletType.evm);
        EvmNativeCurrencies.register(secondLongChainId, secondCurrency, WalletType.evm);

        expect(first.withUniqueTag([second]).tag, "LONGNETWOR");
        expect(second.tag, "LONGNETWOR-1002");
        expect(firstCurrency == secondCurrency, isFalse);
        expect(getChainIdByCryptoCurrency(firstCurrency), firstLongChainId);
        expect(getChainIdByCryptoCurrency(secondCurrency), secondLongChainId);
      });

      test("a chain ID edit does not clash with the network's own saved row", () {
        final saved = network(lookalikeChainId, "Qzx", "QZX", "QZXNET");
        final edited = network(secondLongChainId, "Qzx", "QZX", "QZXNET");

        expect(edited.withUniqueTag([saved], beforeEdit: saved).tag, "QZXNET");
        expect(edited.withUniqueTag([saved]).tag, "QZXNET-1002");
      });

      test("a network with wallets keeps its saved tag", () {
        final saved = network(lookalikeChainId, "Qzx", "QZX", "QZXNET");
        final renamed = network(lookalikeChainId, "BSC", "QZX", "BSC");

        expect(renamed.withUniqueTag([saved], beforeEdit: saved, hasWallets: true).tag, "QZXNET");
        expect(renamed.withUniqueTag([saved], beforeEdit: saved).tag, "BSC-777");
      });

      test("a tag that clashes with nothing is kept", () {
        expect(
          network(lookalikeChainId, "Qzx", "QZX", "QZXNET").withUniqueTag(const []).tag,
          "QZXNET",
        );
      });
    });

    test("chain lookups refuse an unknown chain instead of answering Ethereum", () {
      expect(() => getCryptoCurrencyByChainId(10), throwsException);
      expect(() => walletTypeToCryptoCurrency(WalletType.evm), throwsException);
      expect(getCryptoCurrencyByChainId(addedChainId), same(addedNative));
    });
  });

  group("chain badges", () {
    AddedNetworkCurrency addedNetwork(String? iconUrl) => AddedNetworkCurrency(
          EvmNetwork(
            chainId: addedChainId,
            name: "XYZ Network",
            symbol: "XYZ",
            decimals: 18,
            tag: "XYZNET",
            rpcUrl: "https://rpc.example",
            iconUrl: iconUrl,
          ),
        );

    test("an added network's badge is its own icon, bundled or remote", () {
      const bundled = "assets/new-ui/network_icons/optimism.svg";
      const remote = "https://icons.llamao.fi/icons/chains/rsz_avalanche.jpg";

      expect(addedNetwork(bundled).chainIconPath, bundled);
      expect(addedNetwork(remote).chainIconPath, remote);
      expect(addedNetwork(null).chainIconPath, isNull);
      expect(addedNetwork("").chainIconPath, isNull);
    });

    test("only the built-in badges are glyphs that get a theme tint", () {
      expect(CryptoCurrency.isGlyphChainBadge(CryptoCurrency.eth.chainIconPath!), isTrue);
      expect(CryptoCurrency.isGlyphChainBadge(CryptoCurrency.maticpoly.chainIconPath!), isTrue);
      expect(CryptoCurrency.isGlyphChainBadge("assets/new-ui/network_icons/optimism.svg"), isFalse);
      expect(
        CryptoCurrency.isGlyphChainBadge("https://icons.llamao.fi/icons/chains/rsz_avalanche.jpg"),
        isFalse,
      );
    });
  });
}
