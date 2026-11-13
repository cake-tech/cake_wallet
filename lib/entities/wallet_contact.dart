import "package:cake_wallet/entities/contact_base.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_address_kind.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";

class WalletContact implements ContactBase {
  WalletContact(
    this.address,
    this.name,
    this.type, {
    this.walletType,
    this.label = "",
    this.walletId,
    this.groupId,
    this.walletName,
    this.addressKind,
  });

  @override
  String address;

  @override
  String name;

  @override
  CryptoCurrency type;

  /// Wallet type of the wallet this contact belongs to
  /// Used for EVM chain filtering
  final WalletType? walletType;

  /// Untranslated address-map label, e.g. "Active - P2WPKH"; match on this, never on [name].
  final String label;

  /// [WalletInfo.id] of the wallet this contact belongs to. Opaque, never parsed.
  final String? walletId;

  /// Key of the wallet group this contact belongs to (`walletGroup` row id).
  final String? groupId;

  /// Title of the wallet this contact belongs to, without account or address-type suffix.
  final String? walletName;

  /// Address type (BTC/LTC) or Lightning; null when unknown or not meaningful.
  final WalletAddressKind? addressKind;

  bool get isLightning => addressKind?.isLightning ?? false;

  bool get isActive => label.startsWith("Active");

  bool get isPickable {
    if (type == CryptoCurrency.btc || type == CryptoCurrency.ltc) {
      return isActive;
    }
    return true;
  }

  @override
  String get displayName => "";

  @override
  set displayName(String _) {}

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletContact &&
          other.address == address &&
          other.name == name &&
          other.type == type &&
          other.walletType == walletType &&
          other.label == label &&
          other.walletId == walletId &&
          other.groupId == groupId &&
          other.walletName == walletName &&
          other.addressKind == addressKind;

  @override
  int get hashCode => Object.hash(
      address, name, type, walletType, label, walletId, groupId, walletName, addressKind);
}
