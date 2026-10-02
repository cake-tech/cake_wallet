import "package:cw_core/balance_card_style_settings.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/evm_network.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const cakeIcon = "assets/new-ui/balance_card_icons/cake-card-icon.svg";
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
        gradientIndex: 0,
        useSpecialDesign: false,
        backgroundImagePath: "",
        iconStyleIndex: iconStyleIndex,
        cardOrder: 0,
      );

  group("CardDesign for an added network", () {
    for (final (label, iconUrl, expectedPath) in [
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
        expect(networkCorner.gradient, CardDesign.gradientOrange);
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
      same(CardDesign.ethSpecial),
    );
  });

  test("built-in chains keep their own corner icon and icon styles", () {
    expect(CardDesign.forCurrencyIcon(CryptoCurrency.eth), same(CardDesign.eth));
    expect(CardDesign.forCurrencyIcon(CryptoCurrency.eth).addedNetwork, isNull);

    final paths = CardDesign.iconPathsForWalletType(CryptoCurrency.eth);

    expect(paths, hasLength(6));
    expect(paths.every((path) => path.addedNetwork == null), isTrue);
    expect(paths.last.path, cakeIcon);
  });
}
