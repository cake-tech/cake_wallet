import "package:cake_wallet/core/address_resolver/parsed_address.dart";
import "package:flutter/foundation.dart";

@immutable
sealed class SwapPresentationEvent {
  const SwapPresentationEvent();
}

final class AddressValidationFailed extends SwapPresentationEvent {
  const AddressValidationFailed();
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
