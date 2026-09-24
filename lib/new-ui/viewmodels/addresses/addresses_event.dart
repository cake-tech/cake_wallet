part of "addresses_bloc.dart";

sealed class AddressesEvent {
  const AddressesEvent();
}

final class Init extends AddressesEvent {
  const Init();
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
  const AddressLabelSet(this.entry, this.label);

  final AddressEntry entry;
  final String label;
}

final class AddressAdded extends AddressesEvent {
  const AddressAdded(this.label);

  final String label;
}

final class AddressListRefreshed extends AddressesEvent {
  const AddressListRefreshed();
}

final class _WalletChanged extends AddressesEvent {
  const _WalletChanged();
}
