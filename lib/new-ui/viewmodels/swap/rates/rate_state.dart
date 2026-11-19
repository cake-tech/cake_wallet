part of "rate_cubit.dart";

@immutable
sealed class RateState {

  const RateState();

  RateRequest? get request;

}

final class RatesNotLoaded extends RateState {
  const RatesNotLoaded(this.request);

  @override
  final RateRequest? request;
}

final class RatesLoading extends RateState {
  const RatesLoading(this.request);

  @override
  final RateRequest request;
}

final class RatesLoaded extends RateState {
  RatesLoaded(this.request, this.rates) {
    if(rates.isEmpty) {
      throw ArgumentError("cannot create RatesLoaded with no rates, please use RatesLoadFailed or RatesNotFound instead");
    }
  }

  @override
  final RateRequest request;

  final List<ProviderRate> rates;

  Money? get minLimit {
    final limits = rates.map((r) => r.limits.min);
    if(limits.contains(null)) {
      return null;
    }
    return limits.whereType<Money>().min;
  }

  Money? get maxLimit {
    final limits = rates.map((r) => r.limits.max);
    if(limits.contains(null)) {
      return null;
    }
    return limits.whereType<Money>().max;
  }}

final class RatesNotFound extends RateState {
  const RatesNotFound(this.request);

  @override
  final RateRequest request;
}
