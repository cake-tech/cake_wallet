import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/exchange_limits.dart";
import "package:cw_core/amount/exchange_rate.dart";

class ProviderRate implements Comparable<ProviderRate> {
  ProviderRate({required this.provider, required this.rate, required this.limits});

  final ExchangeProviderDescription provider;
  final ExchangeRate rate;
  final ExchangeLimits limits;

  @override
  int compareTo(ProviderRate other) => rate.compareTo(other.rate);
}
