import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/address_list/address_list_item.dart';

class AddressCell extends StatelessWidget {
  factory AddressCell.fromItem(AddressListItem item,
          {@required bool isCurrent,
          Function(String) onTap,
          Function() onEdit}) =>
      AddressCell(
          address: item.address,
          name: item.name,
          isCurrent: isCurrent,
          onTap: onTap,
          onEdit: onEdit);

  AddressCell(
      {@required this.address,
      @required this.name,
      @required this.isCurrent,
      this.onTap,
      this.onEdit});

  final String address;
  final String name;
  final bool isCurrent;
  final Function(String) onTap;
  final Function() onEdit;

  String get label => name ?? address;

  @override
  Widget build(BuildContext context) {
    const currentTextColor = Colors.blue; // FIXME: Why it's defined here ?
    final currentColor =
        Theme.of(context).accentTextTheme.subtitle.decorationColor;
    final notCurrentColor = Theme.of(context).backgroundColor;
    final notCurrentTextColor =
        Theme.of(context).primaryTextTheme.caption.color;
    final Widget cell = InkWell(
        onTap: () => onTap(address),
        child: Container(
          color: isCurrent ? currentColor : notCurrentColor,
          padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 28),
          child: Text(
            name ?? address,
            style: TextStyle(
              fontSize: name?.isNotEmpty ?? false ? 18 : 10,
              fontWeight: FontWeight.bold,
              color: isCurrent ? currentTextColor : notCurrentTextColor,
            ),
          ),
        ));

    return isCurrent
        ? cell
        : Slidable(
            key: Key(address),
            actionPane: SlidableDrawerActionPane(),
            child: cell,
            secondaryActions: <Widget>[
                IconSlideAction(
                    caption: S.of(context).edit,
                    color: Theme.of(context).primaryTextTheme.overline.color,
                    icon: Icons.edit,
                    onTap: () => onEdit?.call())
              ]);
  }
}
