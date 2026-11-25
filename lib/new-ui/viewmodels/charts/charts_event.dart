part of 'charts_bloc.dart';

@immutable
sealed class ChartsEvent {
  const ChartsEvent();
}

class RangeChanged extends ChartsEvent {
  const RangeChanged({required this.newRange});

  final ChartRange newRange;
}

class SortingCriteriumChanged extends ChartsEvent {
  const SortingCriteriumChanged({required this.newCriterium});

  final PriceDataSortCriterium newCriterium;
}

class CurrencyAdded extends ChartsEvent {
  const CurrencyAdded({required this.currency});

  final CryptoCurrency currency;
}

class CurrencyRemoved extends ChartsEvent {
  const CurrencyRemoved({required this.currency});

  final CryptoCurrency currency;
}

class CurrencyPinned extends ChartsEvent {
  const CurrencyPinned({required this.currency});

  final CryptoCurrency currency;
}

class PageRefreshed extends ChartsEvent {}

class PageLoadStarted extends ChartsEvent {}

class Init extends ChartsEvent {}
