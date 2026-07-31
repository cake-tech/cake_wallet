part of "swap_bloc.dart";

@immutable
sealed class SwapEvent {
  const SwapEvent();
}

final class _Init extends SwapEvent {}

final class SourceChanged extends SwapEvent {
  const SourceChanged(this.newSource);

  final SwapSource newSource;
}

final class SendingWalletChanged extends SwapEvent {
  const SendingWalletChanged(this.newWallet);

  final WalletInfo newWallet;
}

final class PayoutAddressChanged extends SwapEvent {
  const PayoutAddressChanged(this.newAddress);

  final SwapAddress newAddress;
}

final class DepositAmountChanged extends SwapEvent {
  const DepositAmountChanged(this.newAmount);

  final Money newAmount;
}

final class PayoutAmountChanged extends SwapEvent {
  const PayoutAmountChanged(this.newAmount);

  final Money newAmount;
}

final class RatesLoadStarted extends SwapEvent {}

final class DepositCurrencyChanged extends SwapEvent {
  const DepositCurrencyChanged(this.newCurrency);

  final CryptoCurrency newCurrency;
}

final class PayoutCurrencyChanged extends SwapEvent {
  const PayoutCurrencyChanged(this.newCurrency);

  final CryptoCurrency newCurrency;
}

final class MemoChanged extends SwapEvent {
  const MemoChanged(this.newMemo);

  final String newMemo;
}

final class SwapDirectionReversed extends SwapEvent {}

final class ForcedProviderSelected extends SwapEvent {
  const ForcedProviderSelected(this.provider);

  final ExchangeProviderDescription? provider;
}

final class ProviderToggled extends SwapEvent {
  const ProviderToggled(this.provider);

  final ExchangeProviderDescription provider;
}

final class FixedRateToggled extends SwapEvent {}

final class FiatCurrencyChanged extends SwapEvent {
  const FiatCurrencyChanged(this.newCurrency);

  final FiatCurrency newCurrency;
}

final class ForceDecentralizedExchangesToggled extends SwapEvent {}

final class SwapInitiated extends SwapEvent {}

final class SendConfirmed extends SwapEvent {}
