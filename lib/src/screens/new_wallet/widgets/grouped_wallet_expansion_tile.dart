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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        leading: leadingWidget,
        trailing: trailingWidget ?? (childWallets.isEmpty ? SizedBox.shrink() : null),
        title: GestureDetector(
          onTap: onTitleTapped,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: effectiveTextColor,
                ),
            textAlign: TextAlign.left,
          ),
        ),
        children: childWallets.map(
          (item) {
            final currentColor = item.isCurrent
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              key: ValueKey(item.name),
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
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              color: currentColor,
                            ),
                          )
                        : SizedBox(width: 7),
                    SizedBox(width: 24),
                    CakeImageWidget(
                      imageUrl: walletTypeToCryptoCurrency(item.type).iconPath!,
                      width: 32,
                      height: 32,
                    ),
                  ],
                ),
              ),
              title: Text(
                item.name,
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
