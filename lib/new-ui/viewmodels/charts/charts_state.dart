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
  final ChartRange range;
  String priceDisplayStringFor(CryptoCurrency curr);

  const ChartsStateWithData({required this.pinnedCurrency, required this.range});
}

final class ChartsLoading extends ChartsStateWithData {
  @override
  final List<CryptoCurrency> currencies;

  @override
  String priceDisplayStringFor(CryptoCurrency curr) => "...";

  const ChartsLoading({required super.pinnedCurrency, required this.currencies, required super.range});
}

final class ChartsLoaded extends ChartsStateWithData {
  final Map<CryptoCurrency, List<PriceData>> prices;

  List<CryptoCurrency> get currencies => prices.keys.toList();

  @override
  String priceDisplayStringFor(CryptoCurrency curr) => prices[curr]?.lastOrNull?.price ?? "...";

  const ChartsLoaded({required super.pinnedCurrency, required this.prices, required super.range});
}
