import "package:cake_wallet/core/address_resolver/parsed_address.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/foundation.dart";

@immutable
sealed class SwapPresentationEvent {
  const SwapPresentationEvent();
}

final class AddressValidationFailed extends SwapPresentationEvent {
  const AddressValidationFailed(this.currency);

  final CryptoCurrency currency;
}

final class AliaspayAddressFound extends SwapPresentationEvent {
  const AliaspayAddressFound(this.address);

  final ParsedAddress address;
}

final class SwapCreationStarted extends SwapPresentationEvent {
  const SwapCreationStarted();
}

final class SwapAllNotReady extends SwapPresentationEvent {
  const SwapAllNotReady();
}

final class LowFeeAlert extends SwapPresentationEvent {
  const LowFeeAlert();
}

final class RefundAddressRequired extends SwapPresentationEvent {
  const RefundAddressRequired(this.currency);

  final CryptoCurrency currency;
}

final class WalletSwitchFailed extends SwapPresentationEvent {
  const WalletSwitchFailed(this.error);

  final Object error;
}
