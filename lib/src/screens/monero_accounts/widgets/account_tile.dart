import 'package:flutter/material.dart';

class AccountTile extends StatelessWidget {
  AccountTile({
    required this.isCurrent,
    required this.accountName,
    this.accountBalance,
    required this.currency,
    required this.onTap,
    required this.onEdit
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
        ? Theme.of(context).textTheme!.titleSmall!.decorationColor!
        : Theme.of(context).textTheme!.displayLarge!.decorationColor!;
    final textColor = isCurrent
        ? Theme.of(context).textTheme!.titleSmall!.color!
        : Theme.of(context).textTheme!.displayLarge!.color!;

    final Widget cell = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 77,
        padding: EdgeInsets.only(left: 24, right: 24),
        color: color,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
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
             Expanded(
               child: Text(
                '${accountBalance.toString()} $currency',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                  color: Theme.of(context).textTheme!.headlineMedium!.color!,
                  decoration: TextDecoration.none,
                ),
                         ),
             ),
          ],
        ),
      ),
    );
    // FIX-ME: Splidable
    return cell;
    // return Slidable(
    //     key: Key(accountName),
    //     child: cell,
    //     actionPane: SlidableDrawerActionPane(),
    //     secondaryActions: <Widget>[
    //       IconSlideAction(
    //           caption: S.of(context).edit,
    //           color: Colors.blue,
    //           icon: Icons.edit,
    //           onTap: () => onEdit?.call())
    //     ]);
  }
}