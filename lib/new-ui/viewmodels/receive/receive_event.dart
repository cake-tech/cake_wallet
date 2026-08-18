part of "receive_bloc.dart";

sealed class ReceiveEvent {
  const ReceiveEvent();
}

final class ReceiveOpened extends ReceiveEvent {
  const ReceiveOpened({this.initialToken});

  final CryptoCurrency? initialToken;
}

final class AmountChanged extends ReceiveEvent {
  const AmountChanged(this.amount);

  final Money? amount;
}

final class InputCurrencySelected extends ReceiveEvent {
  const InputCurrencySelected(this.currency);

  final Currency currency;
}

final class TokenSelected extends ReceiveEvent {
  const TokenSelected(this.token);

  final CryptoCurrency? token;
}

final class AddressTypeSelected extends ReceiveEvent {
  const AddressTypeSelected(this.option);

  final ReceivePageOption option;
}

final class AddressRotated extends ReceiveEvent {
  const AddressRotated();
}

final class LabelSubmitted extends ReceiveEvent {
  const LabelSubmitted(this.label);

  final String label;
}

final class InfoboxDismissed extends ReceiveEvent {
  const InfoboxDismissed();
}

final class AddressesPageClosed extends ReceiveEvent {
  const AddressesPageClosed();
}

final class _WalletChanged extends ReceiveEvent {
  const _WalletChanged();
}

final class _FiatRateChanged extends ReceiveEvent {
  const _FiatRateChanged(this.fiat);

  final FiatCurrency fiat;
}

final class _PayjoinEndpointChanged extends ReceiveEvent {
  const _PayjoinEndpointChanged();
}
