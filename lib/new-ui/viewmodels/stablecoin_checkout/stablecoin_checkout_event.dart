part of "stablecoin_checkout_bloc.dart";

@immutable
sealed class StablecoinCheckoutEvent {
  const StablecoinCheckoutEvent();
}

final class CoinSelected extends StablecoinCheckoutEvent {
  const CoinSelected(this.coin);

  final StablecoinPaymentData coin;
}

final class NetworkSelected extends StablecoinCheckoutEvent {
  const NetworkSelected(this.network);

  final StablecoinNetwork network;
}

final class NewQuoteRequested extends StablecoinCheckoutEvent {
  const NewQuoteRequested();
}

final class ExpiryTicked extends StablecoinCheckoutEvent {
  const ExpiryTicked(this.now);

  final DateTime now;
}

final class OrderPollTicked extends StablecoinCheckoutEvent {
  const OrderPollTicked();
}

final class BalanceChanged extends StablecoinCheckoutEvent {
  const BalanceChanged();
}
