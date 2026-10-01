import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/evm_network.dart";
import "package:cw_core/wallet_type.dart";
import "package:cw_evm/evm_chain_registry.dart";
import "package:cw_evm/utils/network_chain_utils.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  final registry = EvmChainRegistry();

  // Chain IDs no built-in uses, one per role
  const addedChainId = 777001;
  const secondAddedChainId = 777002;

  EvmNetwork network({
    int chainId = addedChainId,
    String name = "Test Chain",
    String symbol = "TST",
    int decimals = 18,
    String tag = "TSTTAG",
    String? explorerUrl,
    String? iconUrl,
    bool isEnabled = true,
  }) =>
      EvmNetwork(
        chainId: chainId,
        name: name,
        symbol: symbol,
        decimals: decimals,
        tag: tag,
        rpcUrl: "https://rpc.test-chain.example",
        explorerUrl: explorerUrl,
        iconUrl: iconUrl,
        isEnabled: isEnabled,
      );

  tearDown(registry.unregisterAllAddedNetworks);

  group("EvmChainRegistry.registerAddedNetworkChain", () {
    test("registers the chain as an evm chain with its own ChainConfig", () {
      final added = network(explorerUrl: "https://explorer.test-chain.example");

      registry.registerAddedNetworkChain(added);

      final config = registry.getChainConfig(addedChainId)!;
      expect(config.name, "Test Chain");
      expect(config.shortCode, "evm$addedChainId");
      expect(config.caip2, "eip155:$addedChainId");
      expect(config.capabilities.supportsENS, isFalse);
      expect(config.explorerUrls, ["https://explorer.test-chain.example"]);
      expect(registry.getWalletTypeByChainId(addedChainId), WalletType.evm);
      expect(registry.getChainConfigByCaip2("eip155:$addedChainId"), same(config));
      expect(registry.getAddedNetwork(addedChainId), same(added));
      expect(registry.isBuiltinChain(addedChainId), isFalse);
    });

    test("an added chain with no explorer, or an empty one, has no explorer URL", () {
      registry.registerAddedNetworkChain(network());
      registry.registerAddedNetworkChain(network(chainId: secondAddedChainId, explorerUrl: ""));

      expect(registry.getChainConfig(addedChainId)!.explorerUrls, isEmpty);
      expect(registry.getChainConfig(secondAddedChainId)!.explorerUrls, isEmpty);
    });

    test("the native currency's raw is the offset plus the chain ID", () {
      registry.registerAddedNetworkChain(network());

      final currency = registry.getChainConfig(addedChainId)!.nativeCurrency;
      expect(currency, isA<AddedNetworkCurrency>());
      expect(currency.raw, EvmNativeCurrencies.addedNetworkRawOffset + addedChainId);
      expect(currency.raw, 1000000777001);
      expect(currency.title, "TST");
      expect(currency.tag, "TSTTAG");
      expect(currency.decimals, 18);
    });

    test("publishes the native currency to EvmNativeCurrencies as an evm chain", () {
      registry.registerAddedNetworkChain(network());

      final currency = registry.getChainConfig(addedChainId)!.nativeCurrency;
      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(addedChainId), same(currency));
      expect(EvmNativeCurrencies.getWalletTypeByChainId(addedChainId), WalletType.evm);
    });

    test("the icon reaches the currency, the chain badge takes only a bundled one", () {
      registry.registerAddedNetworkChain(
        network(iconUrl: "assets/new-ui/network_icons/optimism.svg"),
      );
      registry.registerAddedNetworkChain(
        network(
          chainId: secondAddedChainId,
          iconUrl: "https://icons.llamao.fi/icons/chains/rsz_test.jpg",
        ),
      );

      final bundled = registry.getChainConfig(addedChainId)!.nativeCurrency;
      final remote = registry.getChainConfig(secondAddedChainId)!.nativeCurrency;
      expect(bundled.iconPath, "assets/new-ui/network_icons/optimism.svg");
      expect(bundled.chainIconPath, "assets/new-ui/network_icons/optimism.svg");
      expect(remote.iconPath, "https://icons.llamao.fi/icons/chains/rsz_test.jpg");
      expect(remote.chainIconPath, isNull);
    });

    test("an icon edit reaches the cached currency without replacing it", () {
      final currency = registry.registerAddedNetworkCurrency(network());

      final edited = registry.registerAddedNetworkCurrency(
        network(iconUrl: "https://icons.llamao.fi/icons/chains/rsz_test.jpg"),
      );

      expect(edited, same(currency));
      expect(edited.iconPath, "https://icons.llamao.fi/icons/chains/rsz_test.jpg");
    });

    test("an added chain never enters the tag map", () {
      registry.registerAddedNetworkChain(network());

      expect(registry.getChainConfigByTag("TSTTAG"), isNull);
    });

    test("an added chain tagged like a built-in leaves the built-in's tag lookup alone", () {
      registry.registerAddedNetworkChain(network(tag: "BSC", symbol: "BNB"));

      expect(registry.getChainConfigByTag("BSC")!.chainId, 56);
      expect(registry.getChainConfigByTag("BSC")!.nativeCurrency, same(CryptoCurrency.bnb));
    });

    test("the evm wallet type has no single chain ID and stays a registered type", () {
      registry.registerAddedNetworkChain(network());

      expect(registry.getChainIdByWalletType(WalletType.evm), isNull);
      expect(registry.getRegisteredWalletTypes(), contains(WalletType.evm));
    });
  });

  group("EvmChainRegistry added network currency", () {
    test("re-registering reuses the same currency instance", () {
      final first = registry.registerAddedNetworkCurrency(network());
      registry.registerAddedNetworkChain(network());

      expect(registry.registerAddedNetworkCurrency(network()), same(first));
      expect(registry.getChainConfig(addedChainId)!.nativeCurrency, same(first));
    });

    test("a rename reaches the cached currency without replacing it", () {
      final currency = registry.registerAddedNetworkCurrency(network(name: "Old Name"));

      final renamed = registry.registerAddedNetworkCurrency(network(name: "New Name"));

      expect(renamed, same(currency));
      expect(renamed.fullName, "New Name");
    });

    test("a symbol change keeps the cached currency until it is unregistered", () {
      final currency = registry.registerAddedNetworkCurrency(network(symbol: "OLD"));

      expect(registry.registerAddedNetworkCurrency(network(symbol: "NEW")).title, "OLD");

      registry.unregisterAddedNetworkCurrency(addedChainId);
      final rebuilt = registry.registerAddedNetworkCurrency(network(symbol: "NEW"));

      expect(rebuilt, isNot(same(currency)));
      expect(rebuilt.title, "NEW");
    });

    test("registering only the currency does not register the chain", () {
      registry.registerAddedNetworkCurrency(network(isEnabled: false));

      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(addedChainId), isNotNull);
      expect(registry.getChainConfig(addedChainId), isNull);
      expect(registry.isChainRegistered(addedChainId), isFalse);
    });
  });

  group("EvmChainRegistry unregister", () {
    test("unregistering the chain keeps its currency, so stored raws still decode", () {
      registry.registerAddedNetworkChain(network());
      final currency = registry.getChainConfig(addedChainId)!.nativeCurrency;

      registry.unregisterAddedNetworkChain(addedChainId);

      expect(registry.getChainConfig(addedChainId), isNull);
      expect(registry.getWalletTypeByChainId(addedChainId), isNull);
      expect(registry.getChainConfigByCaip2("eip155:$addedChainId"), isNull);
      expect(registry.getAddedNetwork(addedChainId), isNull);
      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(addedChainId), same(currency));
      expect(EvmNativeCurrencies.getWalletTypeByChainId(addedChainId), WalletType.evm);
    });

    test("unregistering the currency unpublishes it", () {
      registry.registerAddedNetworkChain(network());
      registry.unregisterAddedNetworkChain(addedChainId);

      registry.unregisterAddedNetworkCurrency(addedChainId);

      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(addedChainId), isNull);
      expect(EvmNativeCurrencies.getWalletTypeByChainId(addedChainId), isNull);
    });

    test("unregisterAllAddedNetworks removes enabled and currency-only networks alike", () {
      registry.registerAddedNetworkChain(network());
      registry.registerAddedNetworkCurrency(network(chainId: secondAddedChainId, isEnabled: false));

      registry.unregisterAllAddedNetworks();

      expect(registry.getChainConfig(addedChainId), isNull);
      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(addedChainId), isNull);
      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(secondAddedChainId), isNull);
    });

    test("unregisterAllAddedNetworks keeps every built-in chain", () {
      registry.registerAddedNetworkChain(network());

      registry.unregisterAllAddedNetworks();

      for (final chainId in [1, 137, 8453, 42161, 56]) {
        expect(registry.getChainConfig(chainId), isNotNull, reason: "$chainId");
        expect(
          EvmNativeCurrencies.getNativeCurrencyByChainId(chainId),
          isNotNull,
          reason: "$chainId",
        );
      }
      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(1), same(CryptoCurrency.eth));
    });
  });

  group("EvmChainRegistry built-in guard", () {
    test("an added network cannot take a built-in chain ID", () {
      for (final chainId in [1, 137, 8453, 42161, 56]) {
        expect(
          () => registry.registerAddedNetworkChain(network(chainId: chainId)),
          throwsArgumentError,
          reason: "$chainId",
        );
        expect(
          () => registry.registerAddedNetworkCurrency(network(chainId: chainId)),
          throwsArgumentError,
          reason: "$chainId",
        );
      }

      expect(registry.getChainConfig(1)!.nativeCurrency, same(CryptoCurrency.eth));
      expect(registry.getWalletTypeByChainId(1), WalletType.ethereum);
      expect(EvmNativeCurrencies.getWalletTypeByChainId(1), WalletType.ethereum);
    });

    test("a built-in chain cannot be unregistered as an added one", () {
      expect(() => registry.unregisterAddedNetworkChain(137), throwsArgumentError);
      expect(() => registry.unregisterAddedNetworkCurrency(8453), throwsArgumentError);

      expect(registry.getChainConfig(137), isNotNull);
      expect(EvmNativeCurrencies.getNativeCurrencyByChainId(8453), same(CryptoCurrency.baseEth));
    });
  });

  group("EvmChainRegistry fee type", () {
    test("Ethereum sends EIP-1559, the four built-in L2s send legacy", () {
      expect(registry.getChainConfig(1)!.feeModel.type, FeeType.eip1559);
      for (final chainId in [137, 8453, 42161, 56]) {
        expect(registry.getChainConfig(chainId)!.feeModel.type, FeeType.legacy, reason: "$chainId");
      }
    });

    test("an added network is EIP-1559, its client falls back to legacy per node", () {
      registry.registerAddedNetworkChain(network());

      expect(registry.getChainConfig(addedChainId)!.feeModel.type, FeeType.eip1559OrLegacy);
    });
  });
}
