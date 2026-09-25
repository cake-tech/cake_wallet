part of "receive_bloc.dart";

sealed class ReceivePresentation {
  const ReceivePresentation();

  String get message;
}

final class ReceiveAddressTypeChangeFailed extends ReceivePresentation {
  const ReceiveAddressTypeChangeFailed();

  @override
  String get message => S.current.receive_error_address_type;
}

final class ReceiveAddressRotationFailed extends ReceivePresentation {
  const ReceiveAddressRotationFailed();

  @override
  String get message => S.current.receive_error_address_rotation;
}

final class ReceiveLabelUpdateFailed extends ReceivePresentation {
  const ReceiveLabelUpdateFailed();

  @override
  String get message => S.current.receive_error_label_update;
}

final class ReceiveInvoiceFetchFailed extends ReceivePresentation {
  const ReceiveInvoiceFetchFailed();

  @override
  String get message => S.current.receive_error_invoice;
}

final class ReceiveFiatRateUnavailable extends ReceivePresentation {
  const ReceiveFiatRateUnavailable();

  @override
  String get message => S.current.receive_error_fiat_rate;
}
