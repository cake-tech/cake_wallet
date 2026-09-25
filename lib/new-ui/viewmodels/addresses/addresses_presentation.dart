part of "addresses_bloc.dart";

sealed class AddressesPresentation {
  const AddressesPresentation();

  String get message;
}

final class AddressesUpdateFailed extends AddressesPresentation {
  const AddressesUpdateFailed();

  @override
  String get message => S.current.receive_error_address_update;
}

final class AddressesLabelUpdateFailed extends AddressesPresentation {
  const AddressesLabelUpdateFailed();

  @override
  String get message => S.current.receive_error_label_update;
}

final class AddressesAddFailed extends AddressesPresentation {
  const AddressesAddFailed();

  @override
  String get message => S.current.receive_error_address_rotation;
}
