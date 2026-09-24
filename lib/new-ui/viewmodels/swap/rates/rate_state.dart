part of "rate_cubit.dart";

@immutable
sealed class RateState {

  const RateState(this.from, this.to);

  final Currency? from;
  final Currency? to;

}

final class RatesNotLoaded extends RateState {
  const RatesNotLoaded(super.from, super.to);
}

final class RatesLoading extends RateState {
  const RatesLoading(super.from, super.to);
}

final class RatesLoaded extends RateState {
  RatesLoaded(super.from, super.to, this.rates) {
    if(rates.isEmpty) {
      throw ArgumentError("cannot create RatesLoaded with no rates, please use RatesLoadFailed or RatesNotFound instead");
    }
  }

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
  const RatesNotFound(super.from, super.to);
}
