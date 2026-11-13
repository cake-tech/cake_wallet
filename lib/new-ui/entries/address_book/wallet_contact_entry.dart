import "package:cake_wallet/entities/wallet_contact.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_address_kind.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";

class WalletContactEntry {
  const WalletContactEntry({
    required this.walletId,
    required this.walletName,
    required this.walletType,
    required this.address,
    required this.currency,
    this.label = "",
    this.displayLabel = "",
    this.accountIndex,
    this.addressKind,
  });

  final String walletId;
  final String walletName;
  final WalletType walletType;
  final String address;
  final CryptoCurrency currency;
  final String label;
  final String displayLabel;
  final int? accountIndex;

  final WalletAddressKind? addressKind;

  bool get isLightning => addressKind?.isLightning ?? false;

  String baseName({String? groupName}) =>
      groupName != null && groupName.trim().isNotEmpty ? groupName.trim() : walletName;

  WalletContact toContact({String? groupId, String? groupName}) {
    final base = baseName(groupName: groupName);
    final account = accountIndex == null ? "" : " [#$accountIndex]";
    final suffix = displayLabel.isNotEmpty ? "($displayLabel)" : "";
    return WalletContact(
      address,
      "$base$account $suffix".trim(),
      currency,
      walletType: walletType,
      label: label,
      walletId: walletId,
      groupId: groupId,
      walletName: base,
      addressKind: addressKind,
    );
  }
}
