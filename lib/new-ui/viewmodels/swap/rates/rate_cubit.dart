import "package:bloc/bloc.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/exchange/provider/exchange_provider.dart";
import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/provider_registry.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/provider_rate.dart";
import "package:cake_wallet/utils/exchange_provider_logger.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:meta/meta.dart";

part "rate_state.dart";

class RateCubit extends Cubit<RateState> {
  RateCubit({required ExchangeProviderRegistry registry})
      : _registry = registry,
        super(const RatesNotLoaded(null));

  final ExchangeProviderRegistry _registry;

  Future<void> fetchRates(
      List<ExchangeProviderDescription> providers,
      RateRequest request, {
        required bool isExternalSend,
      }) async {
    if(request.amount.isZero) {
      emit(RatesNotLoaded(request));
      return;
    }

    if (state is! RatesLoaded || !(state.request?.isSameQuery(request) ?? false)) {
      emit(RatesLoading(request));
    }

    bool supportedForSwap(ExchangeProviderDescription provider) =>
        switch (_registry.getProvider(provider)) {
          TransactionCreationExchangeProvider() ||
          TransactionRegistrationExchangeProvider() => !isExternalSend,
          _ => true,
        };

    final futures = providers
        .where(supportedForSwap)
        .map((provider) async {
          try {
            final rate = await _registry
                .getProvider(provider)
                .fetchRate(request)
                .timeout(const Duration(seconds: 7));

            if(rate.rate.quote.isZero) {
              return null;
            }
            ExchangeProviderLogger.logSuccess(function: "fetchRate",
                provider: provider,
                requestData: request.toJson());
            return rate;

          } catch (e, st) {
            ExchangeProviderLogger.logError(function: "fetchRate",
                provider: provider,
                error: e,
                stackTrace: st,
                requestData: request.toJson());
            printV("failed to fetch rate from ${provider.title}: $e\n$st");
            return null;
          }
        });

    final results = await Future.wait(futures);

    final List<ProviderRate> rates = results.whereType<ProviderRate>().toList();

    if (rates.isEmpty) {
      emit(RatesNotFound(request));
      return;
    }

    rates.sort((a, b) => b.compareTo(a));
    emit(RatesLoaded(request, rates));
  }
}
