import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/entries/address_book/wallet_address_kind.dart";
import "package:cake_wallet/new-ui/pages/address_book/simple_receive_page.dart";
import "package:cake_wallet/new-ui/viewmodels/address_book/wallet_contacts/wallet_contacts_state.dart";
import "package:cake_wallet/new-ui/widgets/image_widgets/wallet_icon_widget.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class GroupedWalletContactsTab extends StatelessWidget {
  const GroupedWalletContactsTab({
    required this.state,
    this.onOtherWalletsTap,
    super.key,
  });

  final WalletContactsState state;
  final VoidCallback? onOtherWalletsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentGroup = state.currentGroup;

    final addressStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      fontFamily: "IBM Plex Mono",
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 128),
      children: [
        if (currentGroup != null) ...[
          NewListSections(
            showHeader: true,
            headerWidgets: {
              currentGroup.name: ListSectionHeader(
                title: currentGroup.name,
                leading: WalletIconAvatar(icon: currentGroup.icon, size: 24, contentSize: 20),
              ),
            },
            sections: {
              currentGroup.name: [
                for (final contact in currentGroup.networkContacts)
                  ListItemRegularRow(
                    keyValue: contact.isLightning
                        ? "address_book_wallet_${contact.walletId}_lightning"
                        : "address_book_wallet_${contact.walletId}_${contact.walletType?.name}",
                    label: contact.isLightning
                        ? WalletAddressKind.lightning.displayName()
                        : contact.walletType != null
                            ? walletTypeToDisplayName(contact.walletType!)
                            : contact.type.title,
                    iconPath: contact.walletType != null
                        ? getNetworkIconForWalletListItem(
                            contact.walletType!,
                            isLightning: contact.addressKind?.isLightning ?? false,
                          )
                        : null,
                    subtitleWidget: Semantics(
                      label: contact.address,
                      child: ExcludeSemantics(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            // A Lightning address is human-readable (user@domain): show it whole.
                            contact.isLightning
                                ? contact.address
                                : AddressFormatter.truncateMiddle(contact.address),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: addressStyle,
                          ),
                        ),
                      ),
                    ),
                    showArrow: false,
                    trailingWidget: Row(
                      spacing: 8,
                      children: [
                        ModernButton.svg(
                          size: 36,
                          iconSize: 24,
                          shape: ModernButtonShape.roundedSquare,
                          svgPath: "assets/new-ui/qr_icon.svg",
                          iconColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surfaceContainerHigh,
                          semanticLabel: S.of(context).show_qr_code,
                          onPressed: () => SimpleReceivePage.show(context, contact),
                        ),
                        ModernButton.svg(
                          size: 36,
                          iconSize: 24,
                          shape: ModernButtonShape.roundedSquare,
                          svgPath: "assets/new-ui/new_copy_icon.svg",
                          iconColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surfaceContainerHigh,
                          semanticLabel: S.of(context).copy_address,
                          onPressed: () => Clipboard.setData(ClipboardData(text: contact.address)),
                        ),
                      ],
                    ),
                  ),
              ],
            },
          ),
          const SizedBox(height: 24),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            S.of(context).address_book_networks_helper,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (onOtherWalletsTap != null)
          NewListSections(
            sections: {
              "": [
                ListItemRegularRow(
                  keyValue: "address_book_other_wallets",
                  label: S.of(context).other_wallets,
                  onTap: onOtherWalletsTap,
                ),
              ],
            },
          ),
      ],
    );
  }
}
