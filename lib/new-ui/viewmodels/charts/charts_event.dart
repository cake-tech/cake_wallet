part of 'charts_bloc.dart';

@immutable
sealed class ChartsEvent {
  const ChartsEvent();
}

class RangeChanged extends ChartsEvent {
  final ChartRange newRange;

  const RangeChanged({required this.newRange});
}

class SortingCriteriumChanged extends ChartsEvent {
  final PriceDataSortCriterium newCriterium;

  const SortingCriteriumChanged({required this.newCriterium});
}

class CurrencyAdded extends ChartsEvent {
  final CryptoCurrency currency;

  const CurrencyAdded({required this.currency});
}

class CurrencyRemoved extends ChartsEvent {
  final CryptoCurrency currency;

  const CurrencyRemoved({required this.currency});
}

class CurrencyPinned extends ChartsEvent {
  final CryptoCurrency currency;

  const CurrencyPinned({required this.currency});
}

class PageRefreshed extends ChartsEvent {}

class PageLoadStarted extends ChartsEvent {}

class Init extends ChartsEvent {}
