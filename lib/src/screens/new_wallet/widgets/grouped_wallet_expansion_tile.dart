import "package:cake_wallet/core/wallet_name_validator.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/new-ui/widgets/image_widgets/wallet_icon_widget.dart";
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';

class GroupedWalletExpansionTile extends StatelessWidget {
  GroupedWalletExpansionTile({
    required this.title,
    required this.isSelected,
    this.childWallets = const [],
    this.onTitleTapped,
    this.onChildItemTapped = _defaultVoidCallback,
    this.onExpansionChanged,
    this.leadingWidget,
    this.walletIcon,
    this.trailingWidget,
    this.childTrailingWidget,
    this.decoration,
    this.color,
    this.textColor,
    this.arrowColor,
    this.borderRadius,
    this.margin,
    this.tileKey,
    this.isCurrentlySelectedWallet = false,
    this.shouldShowCurrentWalletPointer = false,
  }) : super(key: tileKey);

  final Key? tileKey;
  final bool isSelected;
  final bool isCurrentlySelectedWallet;
  final bool shouldShowCurrentWalletPointer;

  final VoidCallback? onTitleTapped;
  final void Function(WalletListItem item) onChildItemTapped;
  final void Function(bool)? onExpansionChanged;

  final String title;
  final Widget? leadingWidget;
  final WalletIcon? walletIcon;

  final Widget? trailingWidget;
  final Widget Function(WalletListItem)? childTrailingWidget;

  final List<WalletListItem> childWallets;

  final Color? color;
  final Color? textColor;
  final Color? arrowColor;
  final EdgeInsets? margin;
  final Decoration? decoration;
  final BorderRadius? borderRadius;

  static void _defaultVoidCallback(WalletListItem ITEM) {}

  @override
  Widget build(BuildContext context) {
    final backgroundColor = color ??
        (isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainer);
    final effectiveTextColor = textColor ??
        (isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface);

    final effectiveArrowColor = arrowColor ??
        (isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant);

    final effectiveLeadingWidget =
        walletIcon != null ? WalletIconAvatar(icon: walletIcon, size: 28, contentSize: 28) : leadingWidget;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(18)),
        collapsedShape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(18)),
        collapsedBackgroundColor: backgroundColor,
        backgroundColor: backgroundColor,
        onExpansionChanged: onExpansionChanged,
        initiallyExpanded: shouldShowCurrentWalletPointer
            ? childWallets.any((element) => element.isCurrent)
            : false,
        key: tileKey,
        tilePadding:
            EdgeInsets.symmetric(vertical: 1, horizontal: !isCurrentlySelectedWallet ? 16 : 0),
        iconColor: effectiveArrowColor,
        collapsedIconColor: effectiveArrowColor,
        leading: (childWallets.isEmpty && onTitleTapped != null && effectiveLeadingWidget != null)
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTitleTapped,
                child: effectiveLeadingWidget,
              )
            : effectiveLeadingWidget,
        trailing: trailingWidget ?? (childWallets.isEmpty ? SizedBox.shrink() : null),
        title: GestureDetector(
          onTap: onTitleTapped,
          child: Text(
            walletNameToDisplay(title),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: effectiveTextColor,
                ),
            textAlign: TextAlign.left,
          ),
        ),
        children: childWallets.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final item = entry.value;
            final currentColor = item.isCurrent
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              key: ValueKey('${index}_${item.name}'),
              trailing: childTrailingWidget?.call(item),
              onTap: () => onChildItemTapped(item),
              leading: SizedBox(
                width: 64,
                child: Row(
                  children: [
                    item.isCurrent && shouldShowCurrentWalletPointer
                        ? Container(
                            height: 35,
                            width: 6,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              color: currentColor,
                            ),
                          )
                        : const SizedBox(width: 7),
                    const SizedBox(width: 24),
                    CakeImageWidget(
                      imageUrl: getCryptoCurrencyIconForWalletListItem(item.type),
                      width: 32,
                      height: 32,
                    ),
                  ],
                ),
              ),
              title: Text(
                item.formatedName ?? item.name,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: effectiveTextColor,
                    ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }
}
