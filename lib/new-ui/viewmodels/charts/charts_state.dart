part of 'charts_bloc.dart';

@immutable
sealed class ChartsState {
  const ChartsState();
}

final class ChartsInitial extends ChartsState {
  const ChartsInitial();
}

abstract final class ChartsStateWithData extends ChartsState {
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

  const ChartsStateWithData(
      {required this.pinnedCurrency, required this.range, required this.sortCriterium});
}

final class ChartsLoading extends ChartsStateWithData {
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

  const ChartsLoading(
      {required super.pinnedCurrency,
      required this.currencies,
      required super.range,
      required super.sortCriterium});
}

final class ChartsLoaded extends ChartsStateWithData {
  final Map<CryptoCurrency, List<PriceData>> _prices;

  @override
  String get fiatTicker => _prices[_prices.keys.first]?.firstOrNull?.from.name ?? "";

  List<CryptoCurrency> get currencies {
    final list = _prices.keys.toList();
    list.sort((a, b) => sortCriterium.comparator(changeDataFor(a), changeDataFor(b), a, b));
    return list;
  }

  @override
  String priceDisplayStringFor(CryptoCurrency curr) => _prices[curr]?.lastOrNull?.price ?? "...";

  PriceChangeData changeDataFor(CryptoCurrency curr) {
    final latestPrice = double.tryParse(_prices[curr]?.lastOrNull?.price ?? "") ?? 0;
    final secondLatestPrice = double.tryParse(_prices[curr]?.firstOrNull?.price ?? "") ?? 0;

    final direction =
        latestPrice >= secondLatestPrice ? PriceChangeDirection.up : PriceChangeDirection.down;
    final percentage = ((latestPrice - secondLatestPrice) / secondLatestPrice * 100).abs();
    final amount = (latestPrice - secondLatestPrice).abs();

    return PriceChangeData(
        direction: direction,
        amount: amount.toStringAsFixed(2),
        percentage: percentage.toStringAsFixed(2));
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
        prices: prices ?? this._prices,
        range: range ?? this.range,
        sortCriterium: sortCriterium ?? this.sortCriterium,
      );

  const ChartsLoaded(
      {required super.pinnedCurrency,
      required Map<CryptoCurrency, List<PriceData>> prices,
      required super.range,
      required super.sortCriterium})
      : _prices = prices;
}
