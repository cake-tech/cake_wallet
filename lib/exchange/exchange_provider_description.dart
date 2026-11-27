import "package:cw_core/enumerable_item.dart";
import "package:cw_core/exceptions/cake_exception.dart";

enum ExchangeProviderDescription implements EnumerableItem<int> {
  xmrto(
    title: "XMR.TO",
    raw: 0,
    image: "assets/new-ui/trade_providers/xmrto.svg",
    isCentralized: true,
  ),
  changeNow(
    title: "ChangeNOW",
    raw: 1,
    image: "assets/new-ui/trade_providers/changenow.svg",
    isCentralized: true,
  ),
  morphToken(
    title: "MorphToken",
    raw: 2,
    image: "assets/new-ui/trade_providers/morph.svg",
    isCentralized: true,
  ),
  sideShift(
    title: "SideShift",
    raw: 3,
    image: "assets/new-ui/trade_providers/sideshift.svg",
    isCentralized: true,
  ),
  simpleSwap(
    title: "SimpleSwap",
    raw: 4,
    image: "assets/new-ui/trade_providers/simpleswap.svg",
    isCentralized: true,
  ),
  trocador(
    title: "Trocador",
    raw: 5,
    image: "assets/new-ui/trade_providers/trocador.svg",
    isCentralized: true,
  ),
  exolix(
    title: "Exolix",
    raw: 6,
    image: "assets/new-ui/trade_providers/exolix.svg",
    isCentralized: true,
  ),
  all(
    title: "All trades",
    raw: 7,
    image: "",
    isCentralized: true,
  ),
  thorChain(
    title: "ThorChain",
    raw: 8,
    image: "assets/new-ui/trade_providers/thorchain.svg",
    isCentralized: true,
  ),
  swapTrade(
    title: "SwapTrade",
    raw: 9,
    image: "assets/new-ui/trade_providers/swaptrade.svg",
    supportsMemoOrDestinationTag: false,
    isCentralized: true,
  ),
  whyNot(
    title: "WhyNot",
    raw: 10,
    image: "assets/new-ui/trade_providers/whynot.svg",
    isCentralized: true,
  ),
  stealthEx(
    title: "StealthEx",
    raw: 11,
    image: "assets/new-ui/trade_providers/stealthex.svg",
    isCentralized: true,
  ),
  chainflip(
    title: "Chainflip",
    raw: 12,
    image: "assets/new-ui/trade_providers/chainflip.svg",
    supportsMemoOrDestinationTag: false,
    isCentralized: false,
  ),
  xoSwap(
    title: "XOSwap",
    raw: 13,
    image: "assets/new-ui/trade_providers/xoswap.svg",
    isCentralized: true,
  ),
  swapsXyz(
    title: "Swaps.XYZ",
    raw: 14,
    image: "assets/new-ui/trade_providers/swaps_xyz.svg",
    supportsMemoOrDestinationTag: false,
    supportsSwapAll: false,
    isCentralized: true,
  ),
  nearIntents(
    title: "Near Intents",
    raw: 15,
    image: "assets/new-ui/trade_providers/near-intents.svg",
    supportsMemoOrDestinationTag: false,
    supportsSwapAll: false,
    isCentralized: false,
  ),
  jupiter(
    title: "Jupiter",
    raw: 16,
    image: "assets/new-ui/trade_providers/jupiter.svg",
    supportsMemoOrDestinationTag: false,
    isCentralized: false,
  ),
  flashnet(
    title: "Flashnet",
    raw: 17,
    supportsMemoOrDestinationTag: false,
    image: "assets/new-ui/trade_providers/flashnet.svg",
    isCentralized: false
  );

  const ExchangeProviderDescription({
    required this.title,
    required this.raw,
    required this.image,
    required this.isCentralized,
    this.supportsSwapAll = true,
    this.supportsMemoOrDestinationTag = true,
  });

  @override
  final String title;

  @override
  final int raw;

  final String image;
  final bool isCentralized;
  final bool supportsSwapAll;
  final bool supportsMemoOrDestinationTag;

  static ExchangeProviderDescription deserialize({required int raw}) {
    for (final provider in ExchangeProviderDescription.values) {
      if (provider.raw == raw) {
        return provider;
      }
    }
    throw DeserializeException(
      "Unexpected token: $raw for ExchangeProviderDescription deserialize",
    );
  }
}