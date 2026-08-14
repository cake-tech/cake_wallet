part of "charts_bloc.dart";

@immutable
sealed class ChartsState {
  const ChartsState();
}

final class ChartsInitial extends ChartsState {
  const ChartsInitial();
}

abstract final class ChartsStateWithData extends ChartsState {
  const ChartsStateWithData({
    required this.pinnedCurrency,
    required this.range,
    required this.sortCriterium,
  });

  final CryptoCurrency pinnedCurrency;

  List<CryptoCurrency> get currencies;

  final PriceDataSortCriterium sortCriterium;
  final ChartRange range;

  String priceDisplayStringFor(CryptoCurrency curr) => "...";

  String get fiatTicker => "";

  bool get hasSingleCurrency => currencies.length == 1;

  ChartsStateWithData copyWith({
    CryptoCurrency? pinnedCurrency,
    ChartRange? range,
    PriceDataSortCriterium? sortCriterium,
  });

  ChartsLoading toLoading() => ChartsLoading(
        pinnedCurrency: pinnedCurrency,
        currencies: currencies,
        range: range,
        sortCriterium: sortCriterium,
      );
}

final class ChartsLoading extends ChartsStateWithData {
  const ChartsLoading({
    required super.pinnedCurrency,
    required this.currencies,
    required super.range,
    required super.sortCriterium,
  });

  @override
  final List<CryptoCurrency> currencies;

  @override
  ChartsLoading copyWith({
    CryptoCurrency? pinnedCurrency,
    List<CryptoCurrency>? currencies,
    ChartRange? range,
    PriceDataSortCriterium? sortCriterium,
  }) =>
      ChartsLoading(
        pinnedCurrency: pinnedCurrency ?? this.pinnedCurrency,
        currencies: currencies ?? this.currencies,
        range: range ?? this.range,
        sortCriterium: sortCriterium ?? this.sortCriterium,
      );
}

final class ChartsLoaded extends ChartsStateWithData {
  const ChartsLoaded({
    required super.pinnedCurrency,
    required Map<CryptoCurrency, List<PriceData>> prices,
    required super.range,
    required super.sortCriterium,
  }) : _prices = prices;
  final Map<CryptoCurrency, List<PriceData>> _prices;

  @override
  String get fiatTicker => _prices[_prices.keys.first]?.firstOrNull?.base.name ?? "";

  @override
  List<CryptoCurrency> get currencies {
    final list = _prices.keys.toList();
    list.sort((a, b) => sortCriterium.comparator(changeDataFor(a), changeDataFor(b), a, b));
    return list;
  }

  @override
  String priceDisplayStringFor(CryptoCurrency curr) => _prices[curr]?.lastOrNull?.quote.toString() ?? "...";

  PriceChangeData changeDataFor(CryptoCurrency curr) {
    final latestPrice = _prices[curr]?.lastOrNull?.quote ?? Money.zero(FiatCurrency.usd);
    final secondLatestPrice = _prices[curr]?.firstOrNull?.quote ?? Money.zero(FiatCurrency.usd);

    final direction =
        latestPrice >= secondLatestPrice ? PriceChangeDirection.up : PriceChangeDirection.down;
    final double percentage;
    if(secondLatestPrice.isZero) {
      percentage = 0;
    } else {
      percentage =
        (((latestPrice.toDouble() - secondLatestPrice.toDouble()) / secondLatestPrice.toDouble()) * 100).abs();
    }
    final amount = (latestPrice - secondLatestPrice).abs();

    return PriceChangeData(
      direction: direction,
      amount: amount,
      percentage: percentage.toStringAsFixed(2),
    );
  }

  List<PriceData> dataFor(CryptoCurrency curr) => _prices[curr] ?? [];

  @override
  ChartsLoaded copyWith({
    CryptoCurrency? pinnedCurrency,
    Map<CryptoCurrency, List<PriceData>>? prices,
    ChartRange? range,
    PriceDataSortCriterium? sortCriterium,
  }) =>
      ChartsLoaded(
        pinnedCurrency: pinnedCurrency ?? this.pinnedCurrency,
        prices: prices ?? _prices,
        range: range ?? this.range,
        sortCriterium: sortCriterium ?? this.sortCriterium,
      );
}
