import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/wallet_list_theme.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class GroupedWalletExpansionTile extends StatelessWidget {
  GroupedWalletExpansionTile({
    required this.title,
    required this.childWallets,
    required this.isSelected,
    required this.onTap,
    this.leadingWidget,
    this.decoration,
    this.color,
    this.textColor,
    this.arrowColor,
  });

  final bool isSelected;
  final VoidCallback onTap;

  final String title;
  final Widget? leadingWidget;
  final List<WalletListItem> childWallets;

  final Color? color;
  final Color? textColor;
  final Color? arrowColor;
  final Decoration? decoration;

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
        borderRadius: BorderRadius.all(Radius.circular(30)),
        color: backgroundColor,
      ),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: ExpansionTile(
          iconColor: effectiveArrowColor,
          collapsedIconColor: effectiveArrowColor,
          leading: leadingWidget,
          title: GestureDetector(
            onTap: onTap,
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
              final walletTypeToCrypto = walletTypeToCryptoCurrency(item.type);
              return GestureDetector(
                onTap: item.onTap ?? onTap,
                child: Container(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                  margin: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Image.asset(
                          walletTypeToCrypto.iconPath!,
                          width: 32,
                          height: 32,
                        ),
                        SizedBox(width: 8),
                        Text(
                          item.name,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: effectiveTextColor,
                          ),
                        ),
                      ],
                    ),
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
