import "package:cw_core/amount/money.dart";

class AddressEntry {
  const AddressEntry({
    required this.address,
    this.id,
    this.label,
    this.isHidden = false,
    this.derivationPath,
    this.txCount,
    this.balance,
  });

  final String address;
  final int? id;
  final String? label;
  final bool isHidden;
  final String? derivationPath;
  final int? txCount;
  final Money? balance;
}

sealed class AddressGroupHeader {
  const AddressGroupHeader();
}

class RegularAddressesHeader extends AddressGroupHeader {
  const RegularAddressesHeader();
}

class HiddenAddressesHeader extends AddressGroupHeader {
  const HiddenAddressesHeader();
}

class AccountsHeader extends AddressGroupHeader {
  const AccountsHeader();
}

class SilentPaymentsReceivedHeader extends AddressGroupHeader {
  const SilentPaymentsReceivedHeader();
}

class AddressGroup {
  const AddressGroup({required this.entries, this.header});

  final AddressGroupHeader? header;
  final List<AddressEntry> entries;
}

class AddressAccount {
  const AddressAccount({required this.id, required this.label});

  final int id;
  final String label;
}
