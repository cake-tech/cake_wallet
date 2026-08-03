import "package:bloc/bloc.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/provider_registry.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/utils/exchange_provider_logger.dart";
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
        super(const RatesNotLoaded(null, null));

  final ExchangeProviderRegistry _registry;

  Future<void> fetchRates(
      List<ExchangeProviderDescription> providers, {
        required Money from,
        required CryptoCurrency to,
        required bool isFixedRate,
      }) async {
    if(from.isZero) {
      emit(RatesNotLoaded(from.currency, to));
      return;
    }

    if (state is! RatesLoaded || from.currency != state.from || to != state.to) {
      emit(RatesLoading(from.currency, to));
    }

    final futures = providers.map((provider) async {
      try {
        final rate = await _registry.getProvider(provider).fetchRate(
          from: from,
          to: to,
          isFixedRate: isFixedRate,
        );

        if(rate.rate.quote.isZero) {
          return null;
        }
        ExchangeProviderLogger.logSuccess(function: "fetchRate",
            provider: provider,
            requestData: {
              "from": from.serialized,
              "to": to.serialized,
              "isFixedRate": isFixedRate
            });
        return rate;

      } catch (e, st) {
        ExchangeProviderLogger.logError(function: "fetchRate",
            provider: provider,
            error: e,
            stackTrace: st,
            requestData: {
              "from": from.serialized,
              "to": to.serialized,
              "isFixedRate": isFixedRate
            });
        printV("failed to fetch rate from ${provider.title}: $e\n$st");
        return null;
      }
    });

    final results = await Future.wait(futures);

    final List<ProviderRate> rates = results.whereType<ProviderRate>().toList();

    if (rates.isEmpty) {
      emit(RatesNotFound(from.currency, to));
      return;
    }

    emit(RatesLoaded(from.currency, to, rates));
  }
}
