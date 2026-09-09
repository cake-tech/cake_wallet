part of "addresses_bloc.dart";

sealed class AddressesEvent {
  const AddressesEvent();
}

final class AddressesOpened extends AddressesEvent {
  const AddressesOpened({this.showHidden = false});

  final bool showHidden;
}

final class SearchTermEntered extends AddressesEvent {
  const SearchTermEntered(this.term);

  final String term;
}

final class ActiveAddressSet extends AddressesEvent {
  const ActiveAddressSet(this.address);

  final String address;
}

final class AddressHideToggled extends AddressesEvent {
  const AddressHideToggled(this.address, {required this.hidden});

  final String address;
  final bool hidden;
}

final class AddressLabelSet extends AddressesEvent {
  const AddressLabelSet(this.address, this.label);

  final String address;
  final String label;
}

final class AddressAdded extends AddressesEvent {
  const AddressAdded(this.label);

  final String label;
}

final class AddressDeleted extends AddressesEvent {
  const AddressDeleted(this.address);

  final String address;
}

final class AddressListRefreshed extends AddressesEvent {
  const AddressListRefreshed();
}

final class _WalletChanged extends AddressesEvent {
  const _WalletChanged();
}
