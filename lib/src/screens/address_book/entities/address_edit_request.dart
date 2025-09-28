import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cw_core/crypto_currency.dart';

enum EditMode {
  contactFields,
  manualAddressAdd,
  manualAddressEdit,
  parsedAddressAdd,
  parsedAddressEdit,
}

class AddressEditRequest {
  factory AddressEditRequest.contact(ContactRecord? c) => AddressEditRequest._(
        contact: c,
        mode: EditMode.contactFields,
      );

  factory AddressEditRequest.address({
    required ContactRecord? contact,
    required CryptoCurrency currency,
    String? label,
    required bool kindIsManual,
    final String? handle,
    String? handleKey,
  }) =>
      AddressEditRequest._(
        contact: contact,
        currency: currency,
        label: label,
        kindIsManual: kindIsManual,
        handleKey: handleKey,
        mode: label == null
            ? (kindIsManual ? EditMode.manualAddressAdd : EditMode.parsedAddressAdd)
            : (kindIsManual ? EditMode.manualAddressEdit : EditMode.parsedAddressEdit),
      );

  const AddressEditRequest._({
    this.contact,
    this.currency,
    this.label,
    this.kindIsManual = false,
    this.handleKey,
    required this.mode,
  });

  final ContactRecord? contact;
  final CryptoCurrency? currency;
  final String? label;
  final bool kindIsManual;
  final EditMode mode;
  final String? handleKey;
}
