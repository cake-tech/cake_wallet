import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/model/charts/util/price_change_data.dart";
import "package:cw_core/crypto_currency.dart";

const List<CryptoCurrency> cryptoCurrenciesByMarketcap = [
  CryptoCurrency.btc,
  CryptoCurrency.eth,
  CryptoCurrency.usdt,
  CryptoCurrency.xrp,
  CryptoCurrency.bnb,
  CryptoCurrency.sol,
  CryptoCurrency.usdc,
  CryptoCurrency.doge,
  CryptoCurrency.trx,
  CryptoCurrency.ton,
  CryptoCurrency.bch,
  CryptoCurrency.ltc,
  CryptoCurrency.xmr,
  CryptoCurrency.matic,
  CryptoCurrency.arb,
  CryptoCurrency.dai,
  CryptoCurrency.paxg,
  CryptoCurrency.zec,
  CryptoCurrency.dcr,
  CryptoCurrency.nano,
  CryptoCurrency.zano,
  CryptoCurrency.deuro,
  CryptoCurrency.wow,
];

abstract class PriceDataSortCriterium {
  const PriceDataSortCriterium();

  String get name;

  String get iconPath;

  int comparator(
    PriceChangeData changeDataA,
    PriceChangeData changeDataB,
    CryptoCurrency a,
    CryptoCurrency b,
  );

  static const all = [
    MarketcapSortCriterium(),
    GainsSortCriterium(),
    LossesSortCriterium(),
    AlphabeticalSortCriterium(),
  ];
}

class AlphabeticalSortCriterium extends PriceDataSortCriterium {
  const AlphabeticalSortCriterium();

  @override
  String get name => S.current.alphabetical;

  @override
  String get iconPath => "assets/new-ui/charts_sort_criteria/alpha.svg";

  @override
  int comparator(
    PriceChangeData changeDataA,
    PriceChangeData changeDataB,
    CryptoCurrency a,
    CryptoCurrency b,
  ) =>
      (a.fullName ?? a.title).compareTo(b.fullName ?? b.title);
}

class MarketcapSortCriterium extends PriceDataSortCriterium {
  const MarketcapSortCriterium();

  @override
  String get name => S.current.marketcap;

  @override
  String get iconPath => "assets/new-ui/charts_sort_criteria/marketcap.svg";

  @override
  int comparator(
    PriceChangeData changeDataA,
    PriceChangeData changeDataB,
    CryptoCurrency a,
    CryptoCurrency b,
  ) {
    final aIndex = cryptoCurrenciesByMarketcap.indexOf(a);
    final bIndex = cryptoCurrenciesByMarketcap.indexOf(b);

    if (aIndex != -1 && bIndex != -1) {
      return aIndex.compareTo(bIndex);
    }
    if (aIndex != -1) {
      return -1;
    }
    if (bIndex != -1) {
      return 1;
    }

    return (a.fullName ?? a.title).compareTo(b.fullName ?? b.title);
  }
}

class GainsSortCriterium extends PriceDataSortCriterium {
  const GainsSortCriterium();

  @override
  String get name => S.current.gains;

  @override
  String get iconPath => "assets/new-ui/charts_sort_criteria/gains.svg";

  @override
  int comparator(
    PriceChangeData changeDataA,
    PriceChangeData changeDataB,
    CryptoCurrency a,
    CryptoCurrency b,
  ) =>
      changeDataB.compareTo(changeDataA);
}

class LossesSortCriterium extends PriceDataSortCriterium {
  const LossesSortCriterium();

  @override
  String get name => S.current.losses;

  @override
  String get iconPath => "assets/new-ui/charts_sort_criteria/losses.svg";

  @override
  int comparator(
    PriceChangeData changeDataA,
    PriceChangeData changeDataB,
    CryptoCurrency a,
    CryptoCurrency b,
  ) =>
      changeDataA.compareTo(changeDataB);
}
