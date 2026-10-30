part of "stablecoin_checkout_bloc.dart";

@immutable
sealed class StablecoinCheckoutState {
  const StablecoinCheckoutState(this.coin, [this.network]);

  final StablecoinPaymentData coin;
  final StablecoinNetwork? network;
}

sealed class StablecoinCheckoutSelectable extends StablecoinCheckoutState {
  const StablecoinCheckoutSelectable(super.coin, [super.network]);
}

final class StablecoinCheckoutReady extends StablecoinCheckoutSelectable {
  const StablecoinCheckoutReady(super.coin);
}

final class StablecoinCheckoutLoading extends StablecoinCheckoutState {
  const StablecoinCheckoutLoading(super.coin, super.network);
}

final class StablecoinCheckoutQuoted extends StablecoinCheckoutSelectable {
  const StablecoinCheckoutQuoted(
    super.coin,
    super.network,
    this.quote, {
    required this.deadline,
    required this.canPayInCakeWallet,
  });

  final CakePayStablecoinQuote quote;
  final DateTime deadline;
  final bool canPayInCakeWallet;

  PaymentRequest get paymentRequest => quote.paymentRequest.contains(":")
      ? PaymentRequest.fromString(quote.paymentRequest)
      : PaymentRequest(
          quote.address,
          quote.amount,
          "",
          quote.chain,
          null,
          contractAddress: quote.contract,
        );
}

final class StablecoinCheckoutQuoteExpired extends StablecoinCheckoutSelectable {
  const StablecoinCheckoutQuoteExpired(super.coin, super.network);
}

final class StablecoinCheckoutFailure extends StablecoinCheckoutSelectable {
  const StablecoinCheckoutFailure(super.coin, super.network, this.message);

  final String message;
}

final class StablecoinCheckoutOrderExpired extends StablecoinCheckoutState {
  const StablecoinCheckoutOrderExpired(super.coin, super.network);
}

final class StablecoinCheckoutOrderStatusChanged extends StablecoinCheckoutState {
  const StablecoinCheckoutOrderStatusChanged(super.coin, super.network, this.orderRecord);

  final Order? orderRecord;
}
