class AddressEntry {
  const AddressEntry({
    required this.address,
    this.id,
    this.label,
    this.isPrimary = false,
    this.isChange = false,
    this.isHidden = false,
    this.isManual = false,
    this.isLegacyDerivation = false,
    this.isOneTimeReceiveAddress = false,
    this.derivationPath,
    this.txCount,
    this.balance,
  });

  final String address;
  final int? id;
  final String? label;
  final bool isPrimary;
  final bool isChange;
  final bool isHidden;
  final bool isManual;
  final bool isLegacyDerivation;
  final bool isOneTimeReceiveAddress;
  final String? derivationPath;
  final int? txCount;
  final String? balance;
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
