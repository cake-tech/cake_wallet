import "package:cake_wallet/entities/wallet_contact.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cw_core/wallet_type.dart";

class WalletContactGroup {
  const WalletContactGroup({
    required this.groupId,
    required this.name,
    required this.icon,
    required this.isCurrent,
    required this.contacts,
    this.canManageNetworks = false,
  });

  final String groupId;
  final String name;
  final WalletIcon icon;

  final bool isCurrent;
  final bool canManageNetworks;
  final List<WalletContact> contacts;

  List<WalletContact> get networkContacts {
    final byNetwork = <(Object, bool), WalletContact>{};
    final lightningByWallet = <String, WalletContact>{};
    for (final contact in contacts) {
      if (contact.isLightning) {
        final walletId = contact.walletId;
        if (walletId != null) lightningByWallet.putIfAbsent(walletId, () => contact);
        continue;
      }
      final key = (contact.walletType ?? contact.type, false);
      final existing = byNetwork[key];
      if (existing == null || (!existing.isActive && contact.isActive)) {
        byNetwork[key] = contact;
      }
    }

    return [
      for (final contact in byNetwork.values) ...[
        if (contact.walletType == WalletType.bitcoin && lightningByWallet[contact.walletId] != null)
          lightningByWallet[contact.walletId]!,
        contact,
      ],
    ];
  }

  WalletContactGroup copyWith({bool? isCurrent, List<WalletContact>? contacts}) =>
      WalletContactGroup(
        groupId: groupId,
        name: name,
        icon: icon,
        isCurrent: isCurrent ?? this.isCurrent,
        contacts: contacts ?? this.contacts,
        canManageNetworks: canManageNetworks,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletContactGroup &&
          other.groupId == groupId &&
          other.name == name &&
          other.icon == icon &&
          other.isCurrent == isCurrent &&
          other.canManageNetworks == canManageNetworks &&
          _sameContacts(other.contacts, contacts);

  @override
  int get hashCode => Object.hash(
      groupId, name, icon, isCurrent, canManageNetworks, Object.hashAll(contacts.map(_contactKey)));

  static bool _sameContacts(List<WalletContact> a, List<WalletContact> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (_contactKey(a[i]) != _contactKey(b[i])) return false;
    }
    return true;
  }

  static Object _contactKey(WalletContact c) => (
        c.address,
        c.name,
        c.type,
        c.walletType,
        c.label,
        c.walletId,
        c.groupId,
        c.walletName,
        c.addressKind,
      );
}
