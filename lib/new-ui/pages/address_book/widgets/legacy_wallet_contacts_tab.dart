import "package:cake_wallet/entities/contact_base.dart";
import "package:cake_wallet/entities/wallet_contact.dart";
import "package:cake_wallet/new-ui/viewmodels/address_book/wallet_contacts/wallet_contacts_state.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/standard_list.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:flutter/material.dart";

class LegacyWalletContactsTab extends StatelessWidget {
  const LegacyWalletContactsTab({
    required this.state,
    required this.onContactTap,
    super.key,
  });

  final WalletContactsState state;
  final void Function(ContactBase contact) onContactTap;

  @override
  Widget build(BuildContext context) {
    final groupedContacts = <String, List<WalletContact>>{};
    for (final contact in state.allContacts) {
      groupedContacts.putIfAbsent(contact.walletId ?? contact.address, () => []).add(contact);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 128),
      itemCount: groupedContacts.length * 2,
      itemBuilder: (context, index) {
        if (index.isOdd) return StandardListSeparator(height: 0);

        final groupContacts = groupedContacts.values.elementAt(index ~/ 2);

        if (groupContacts.length == 1) {
          return _ContactTile(contact: groupContacts[0], onTap: onContactTap);
        }

        final activeContact = groupContacts.firstWhere(
          (contact) => contact.isActive,
          orElse: () => groupContacts[0],
        );

        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
          child: ExpansionTile(
            title: Text(
              activeContact.walletName ?? activeContact.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            leading: _ContactIcon(contact: activeContact),
            tilePadding: const EdgeInsets.only(left: 16, right: 16),
            childrenPadding: const EdgeInsets.only(left: 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            expandedAlignment: Alignment.topLeft,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            collapsedBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            children: [
              for (final contact in groupContacts)
                _ContactTile(contact: contact, onTap: onContactTap),
            ],
          ),
        );
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact, required this.onTap});

  final ContactBase contact;
  final void Function(ContactBase contact) onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onTap(contact),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          margin: const EdgeInsets.only(top: 4, bottom: 4, left: 16, right: 16),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _ContactIcon(contact: contact),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    contact.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium!,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ContactIcon extends StatelessWidget {
  const _ContactIcon({required this.contact});

  final ContactBase contact;

  @override
  Widget build(BuildContext context) {
    final image = walletContactIconPath(contact);
    return image != null
        ? CakeImageWidget(imageUrl: image, height: 24, width: 24)
        : const SizedBox(height: 24, width: 24);
  }
}

String? walletContactIconPath(ContactBase contact) {
  final image = (contact is WalletContact && contact.walletType != null)
      ? getCryptoCurrencyIconForWalletListItem(contact.walletType!)
      : contact.type.iconPath;
  return (image != null && image.isNotEmpty) ? image : null;
}
