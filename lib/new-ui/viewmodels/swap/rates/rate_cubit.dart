import "package:bloc/bloc.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/provider_registry.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:meta/meta.dart";

part "rate_state.dart";

class RateCubit extends Cubit<RateState> {
  RateCubit({required ExchangeProviderRegistry registry})
      : _registry = registry,
        super(const RatesLoading(null, null));

  final ExchangeProviderRegistry _registry;

  Future<void> fetchRates(
    List<ExchangeProviderDescription> providers, {
    required Money from,
    required CryptoCurrency to,
    required bool isFixedRate,
  }) async {
      if(from.currency != state.from || to != state.to) {
        emit(RatesLoading(from.currency, to));
      }

    final List<ProviderRate> rates = [];
    for (final provider in providers) {
      try {
        rates.add(await _registry.getProvider(provider).fetchRate(
              from: from,
              to: to,
              isFixedRate: isFixedRate,
            ));
      } catch (e, st) {
        printV("failed to fetch rate from ${provider.title}: $e\n$st");
      }
    }
    emit(RatesLoaded(from.currency, to, rates));
  }
}
