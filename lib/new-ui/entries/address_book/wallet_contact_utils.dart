import "package:cake_wallet/core/wallet_name_validator.dart";
import "package:cake_wallet/entities/contact_base.dart";
import "package:cake_wallet/entities/wallet_contact.dart";
import "package:cake_wallet/entities/wallet_contact_group.dart";
import "package:cake_wallet/entities/wallet_group.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_contact_entry.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/utils/token_utilities.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";

typedef ChainIdForWalletType = int Function(WalletType type);

/// Whether [contact] can be picked for [currency] (null = no filter).
///
/// Same rules as the former `ContactListViewModel._isValidForCurrency`: wallet contacts must
/// be pickable, the currency matches by value, tag/tag, tag/title or title/tag, and EVM wallet
/// contacts must be on the currency's chain (skipped when [chainIdForWalletType] is null).
///
/// The wallet's own Lightning address is never offered for a currency filter.
bool isContactValidForCurrency(
  ContactBase contact,
  CryptoCurrency? currency, {
  required bool isWalletContact,
  ChainIdForWalletType? chainIdForWalletType,
}) {
  if (currency == null) return true;
  if (contact is WalletContact && contact.isLightning) return false;
  if (isWalletContact && contact is WalletContact && !contact.isPickable) return false;

  final type = contact.type;
  final currencyMatches = type == currency;
  final tagsMatch = type.tag != null && currency.tag != null && type.tag == currency.tag;
  final tagMatchesTitle = currency.tag != null && currency.tag == type.title;
  final titleMatchesTag = currency.title == type.tag;

  var matches = currencyMatches || tagsMatch || tagMatchesTitle || titleMatchesTag;

  if (matches &&
      isWalletContact &&
      contact is WalletContact &&
      contact.walletType != null &&
      chainIdForWalletType != null &&
      isEVMCompatibleChain(contact.walletType!)) {
    final currencyChainId = TokenUtilities.getChainId(currency);
    final walletChainId = chainIdForWalletType(contact.walletType!);
    if (currencyChainId != walletChainId) matches = false;
  }

  return matches;
}

/// Maps wallet groups and their wallets' cached entries to Address Book groups.
///
/// No I/O. Contacts get the group's id and name, the [currency] filter is applied per contact,
/// groups without contacts are dropped, and the current group comes first (others keep order).
List<WalletContactGroup> buildWalletContactGroups({
  required List<WalletGroup> groups,
  required Map<String, List<WalletContactEntry>> entriesByWalletId,
  String? currentGroupId,
  CryptoCurrency? currency,
  ChainIdForWalletType? chainIdForWalletType,
}) {
  final result = <WalletContactGroup>[];

  for (final group in groups) {
    final readyWallets = group.wallets.where((w) => w.isReady).toList();
    if (readyWallets.isEmpty) continue;

    final groupName = group.groupName?.trim().isNotEmpty == true ? group.groupName : null;
    final contacts = [
      for (final wallet in readyWallets)
        for (final entry in entriesByWalletId[wallet.id] ?? const <WalletContactEntry>[])
          entry.toContact(groupId: group.groupKey, groupName: groupName),
    ]
        .where((c) => isContactValidForCurrency(c, currency,
            isWalletContact: true, chainIdForWalletType: chainIdForWalletType))
        .toList();
    if (contacts.isEmpty) continue;

    result.add(WalletContactGroup(
      groupId: group.groupKey,
      name: groupName ?? walletNameToDisplay(readyWallets.first.name),
      icon: group.icon ?? WalletIcon.defaultIcon,
      isCurrent: group.groupKey == currentGroupId,
      canManageNetworks: group.canManageNetworks,
      contacts: List.unmodifiable(contacts),
    ));
  }

  final current = result.where((g) => g.isCurrent);
  return [...current, ...result.where((g) => !g.isCurrent)];
}

