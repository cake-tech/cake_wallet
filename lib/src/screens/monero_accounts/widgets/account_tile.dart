import 'package:cake_wallet/themes/extensions/account_list_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cake_wallet/generated/i18n.dart';

class AccountTile extends StatelessWidget {
  AccountTile({
    required this.isCurrent,
    required this.accountName,
    this.accountBalance,
    required this.currency,
    required this.onTap,
    required this.onEdit,
  });

  final bool isCurrent;
  final String accountName;
  final String? accountBalance;
  final String currency;
  final Function() onTap;
  final Function() onEdit;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? Theme.of(context).extension<AccountListTheme>()!.currentAccountBackgroundColor
        : Theme.of(context).extension<AccountListTheme>()!.tilesBackgroundColor;
    final textColor = isCurrent
        ? Theme.of(context).extension<AccountListTheme>()!.currentAccountTextColor
        : Theme.of(context).extension<AccountListTheme>()!.tilesTextColor;

    final Widget cell = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: double.infinity,
        padding: EdgeInsets.only(left: 24, right: 24),
        color: color,
        child: Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              child: Text(
                accountName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                  color: textColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            if (accountBalance != null)
              Container(
                child: Text(
                  '${accountBalance.toString()} $currency',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lato',
                    color: isCurrent
                        ? Theme.of(context).extension<AccountListTheme>()!.currentAccountAmountColor
                        : Theme.of(context).extension<AccountListTheme>()!.tilesAmountColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // return cell;
    return Slidable(key: Key(accountName), child: cell, endActionPane: _actionPane(context));
  }

  ActionPane _actionPane(BuildContext context) => ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.3,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit.call(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: S.of(context).edit,
          ),
        ],
      );
}
