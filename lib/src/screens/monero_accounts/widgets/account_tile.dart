import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cake_wallet/generated/i18n.dart';

class AccountTile extends StatelessWidget {
  AccountTile({
    required this.isCurrent,
    required this.accountName,
    required this.onTap,
    required this.onEdit
  });

  final bool isCurrent;
  final String accountName;
  final Function() onTap;
  final Function() onEdit;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? Theme.of(context).textTheme!.subtitle2!.decorationColor!
        : Theme.of(context).textTheme!.headline1!.decorationColor!;
    final textColor = isCurrent
        ? Theme.of(context).textTheme!.subtitle2!.color!
        : Theme.of(context).textTheme!.headline1!.color!;

    final Widget cell = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 77,
        padding: EdgeInsets.only(left: 24, right: 24),
        alignment: Alignment.centerLeft,
        color: color,
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