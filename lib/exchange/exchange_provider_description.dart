import 'package:cw_core/enumerable_item.dart';

class ExchangeProviderDescription extends EnumerableItem<int> with Serializable<int> {
  const ExchangeProviderDescription(
      {required String title, required int raw, required this.image, this.horizontalLogo = false, required this.isCentralized})
      : super(title: title, raw: raw);

  final bool horizontalLogo;
  final String image;
  final bool isCentralized;

  static const xmrto =
      ExchangeProviderDescription(title: 'XMR.TO', raw: 0, image: 'assets/new-ui/trade_providers/xmrto.svg', isCentralized: true);
  static const changeNow =
      ExchangeProviderDescription(title: 'ChangeNOW', raw: 1, image: 'assets/new-ui/trade_providers/changenow.svg', isCentralized: true);
  static const morphToken =
      ExchangeProviderDescription(title: 'MorphToken', raw: 2, image: 'assets/new-ui/trade_providers/morph.svg', isCentralized: true);
  static const sideShift =
      ExchangeProviderDescription(title: 'SideShift', raw: 3, image: 'assets/new-ui/trade_providers/sideshift.svg', isCentralized: true);
  static const simpleSwap =
      ExchangeProviderDescription(title: 'SimpleSwap', raw: 4, image: 'assets/new-ui/trade_providers/simpleswap.svg', isCentralized: true);
  static const trocador =
      ExchangeProviderDescription(title: 'Trocador', raw: 5, image: 'assets/new-ui/trade_providers/trocador.svg', isCentralized: true);
  static const exolix =
      ExchangeProviderDescription(title: 'Exolix', raw: 6, image: 'assets/new-ui/trade_providers/exolix.svg', isCentralized: true);
  static const all =
      ExchangeProviderDescription(title: 'All trades', raw: 7, image: '', isCentralized: true);
  static const thorChain =
      ExchangeProviderDescription(title: 'ThorChain', raw: 8, image: 'assets/new-ui/trade_providers/thorchain.svg', isCentralized: true);
  static const swapTrade =
      ExchangeProviderDescription(title: 'SwapTrade', raw: 9, image: 'assets/new-ui/trade_providers/swaptrade.svg', isCentralized: true);
  static const letsExchange =
      ExchangeProviderDescription(title: 'LetsExchange', raw: 10, image: 'assets/new-ui/trade_providers/letsexchange.svg', isCentralized: true);
  static const stealthEx =
      ExchangeProviderDescription(title: 'StealthEx', raw: 11, image: 'assets/new-ui/trade_providers/stealthex.svg', isCentralized: true);
  static const chainflip =
      ExchangeProviderDescription(title: 'Chainflip', raw: 12, image: 'assets/new-ui/trade_providers/chainflip.svg', isCentralized: false);
  static const xoSwap =
      ExchangeProviderDescription(title: 'XOSwap', raw: 13, image: 'assets/new-ui/trade_providers/xoswap.svg', isCentralized: true);
  static const swapsXyz =
      ExchangeProviderDescription(title: 'Swaps.XYZ', raw: 14, image: 'assets/new-ui/trade_providers/swaps_xyz.svg', isCentralized: false);
  static const nearIntents =
      ExchangeProviderDescription(title: 'Near Intents', raw: 15, image: 'assets/new-ui/trade_providers/near-intents.svg', isCentralized: false);
  static const jupiter =
      ExchangeProviderDescription(title: 'Jupiter', raw: 16, image: 'assets/new-ui/trade_providers/jupiter.svg', isCentralized: false);

  static ExchangeProviderDescription deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return xmrto;
      case 1:
        return changeNow;
      case 2:
        return morphToken;
      case 3:
        return sideShift;
      case 4:
        return simpleSwap;
      case 5:
        return trocador;
      case 6:
        return exolix;
      case 7:
        return all;
      case 8:
        return thorChain;
      case 9:
        return swapTrade;
      case 10:
        return letsExchange;
      case 11:
        return stealthEx;
      case 12:
        return chainflip;
      case 13:
        return xoSwap;
      case 14:
        return swapsXyz;
      case 15:
        return nearIntents;
      case 16:
        return jupiter;
      default:
        throw Exception('Unexpected token: $raw for ExchangeProviderDescription deserialize');
    }
  }
}
