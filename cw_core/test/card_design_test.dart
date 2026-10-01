import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/evm_network.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const cakeIcon = "assets/new-ui/balance_card_icons/cake-card-icon.svg";
  const bundledIcon = "assets/new-ui/network_icons/optimism.svg";
  const remoteIcon = "https://icons.llamao.fi/icons/chains/rsz_avalanche.jpg";

  AddedNetworkCurrency addedNetwork(String? iconUrl) => AddedNetworkCurrency(
        EvmNetwork(
          chainId: 43114,
          name: "Avalanche C-Chain",
          symbol: "AVAX",
          decimals: 18,
          tag: "AVAX",
          rpcUrl: "https://rpc.example",
          iconUrl: iconUrl,
        ),
      );

  BalanceCardStyleSettings savedCornerIcon(int iconStyleIndex) => BalanceCardStyleSettings(
        walletInfoId: 1,
        accountIndex: -1,
        gradientIndex: 3,
        useSpecialDesign: false,
        backgroundImagePath: "",
        iconStyleIndex: iconStyleIndex,
        cardOrder: 0,
      );

  group("CardDesign for an added network", () {
    for (final (label, iconUrl, expectedPath) in [
      ("bundled", bundledIcon, bundledIcon),
      ("remote", remoteIcon, remoteIcon),
      ("missing", null, ""),
    ]) {
      test("offers the network icon then the Cake icon when the icon is $label", () {
        final network = addedNetwork(iconUrl);

        final paths = CardDesign.iconPathsForWalletType(network);

        expect(paths.map((path) => path.path), [expectedPath, cakeIcon]);
        expect(paths.first.addedNetwork, same(network));
        expect(paths.first.preColored, isTrue);
        expect(paths.last.addedNetwork, isNull);
      });

      test("draws the network icon in the corner when the icon is $label", () {
        final network = addedNetwork(iconUrl);

        final design = CardDesign.forCurrencyIcon(network);

        expect(design.backgroundType, CardDesignBackgroundTypes.svgIcon);
        expect(design.imagePath, expectedPath);
        expect(design.addedNetwork, same(network));
        expect(design.preColoredIcon, isTrue);
      });

      test("maps a saved icon style index to the network icon or the Cake icon when $label", () {
        final network = addedNetwork(iconUrl);

        final networkCorner = CardDesign.fromStyleSettings(savedCornerIcon(0), network);
        final cakeCorner = CardDesign.fromStyleSettings(savedCornerIcon(1), network);

        expect(networkCorner.imagePath, expectedPath);
        expect(networkCorner.addedNetwork, same(network));
        expect(networkCorner.gradient, CardDesign.allGradients[3]);
        expect(cakeCorner.imagePath, cakeIcon);
        expect(cakeCorner.addedNetwork, isNull);
        expect(cakeCorner.preColoredIcon, isFalse);
      });

      test("starts with the network icon in the corner before any style is saved when $label", () {
        final network = addedNetwork(iconUrl);

        final design = CardDesign.fromStyleSettings(null, network);

        expect(design.backgroundType, CardDesignBackgroundTypes.svgIcon);
        expect(design.imagePath, expectedPath);
        expect(design.addedNetwork, same(network));
      });
    }
  });

  test("a built-in chain with no saved style keeps its special design", () {
    expect(
      CardDesign.fromStyleSettings(null, CryptoCurrency.eth),
      same(CardDesign.forCurrencySpecial(CryptoCurrency.eth)),
    );
  });

  test("built-in chains keep their own corner icon and icon styles", () {
    expect(CardDesign.forCurrencyIcon(CryptoCurrency.eth), same(CardDesign.eth));
    expect(CardDesign.forCurrencyIcon(CryptoCurrency.eth).addedNetwork, isNull);
    expect(
      CardDesign.iconPathsForWalletType(CryptoCurrency.eth).map((path) => path.path),
      [
        "assets/new-ui/card_icons/symbol_icons/eth-symbol.svg",
        "assets/new-ui/card_icons/outline_icons/eth-outline.svg",
        "assets/new-ui/balance_card_icons/ethereum.svg",
        "assets/new-ui/card_icons/chain_icons/ethereum.svg",
        "assets/new-ui/card_icons/og_icons/eth-og.svg",
        cakeIcon,
      ],
    );
  });
}
