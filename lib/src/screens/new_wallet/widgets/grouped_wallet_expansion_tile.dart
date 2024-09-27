import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/wallet_list_theme.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

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
    final backgroundColor = color ?? (isSelected ? Colors.green : Theme.of(context).cardColor);
    final effectiveTextColor = textColor ??
        (isSelected
            ? Theme.of(context).extension<WalletListTheme>()!.restoreWalletButtonTextColor
            : Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor);

    final effectiveArrowColor = arrowColor ??
        (isSelected
            ? Theme.of(context).extension<WalletListTheme>()!.restoreWalletButtonTextColor
            : Theme.of(context).extension<FilterTheme>()!.titlesColor);
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.all(Radius.circular(30)),
        color: backgroundColor,
      ),
      margin: margin ?? const EdgeInsets.only(bottom: 12.0),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: ExpansionTile(
          onExpansionChanged: onExpansionChanged,
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
              style: TextStyle(
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
                  ? Theme.of(context)
                      .extension<WalletListTheme>()!
                      .createNewWalletButtonBackgroundColor
                  : Theme.of(context).colorScheme.background;
              final walletTypeToCrypto = walletTypeToCryptoCurrency(item.type);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                key: ValueKey(item.name),
                trailing: childTrailingWidget?.call(item),
                onTap: () => onChildItemTapped(item),
                leading: SizedBox(
                  width: 60,
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
                          : SizedBox(width: 6),
                      SizedBox(width: 16),
                      Image.asset(
                        walletTypeToCrypto.iconPath!,
                        width: 32,
                        height: 32,
                      ),
                    ],
                  ),
                ),
                title: Text(
                  item.name,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: effectiveTextColor,
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}
