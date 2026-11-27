part of "swap_currency_cubit.dart";

@immutable
sealed class SwapCurrencyState {
  const SwapCurrencyState();
}

final class SwapCurrenciesNotLoaded extends SwapCurrencyState {
  const SwapCurrenciesNotLoaded();
}

sealed class SwapCurrenciesWithList extends SwapCurrencyState {
  SwapCurrenciesWithList({required this.known, required this.external})
    : currencies = SwapCurrencyCubit._withoutExcluded([
        ...known,
        ...external.where((c) => !c.disabled),
      ]);

  final List<CryptoCurrency> known;

  final List<ExternalCurrency> external;

  final List<CryptoCurrency> currencies;
}

final class SwapCurrenciesRefreshing extends SwapCurrenciesWithList {
  SwapCurrenciesRefreshing({required super.known, required super.external});
}

final class SwapCurrenciesLoaded extends SwapCurrenciesWithList {
  SwapCurrenciesLoaded({required super.known, required super.external});
}
