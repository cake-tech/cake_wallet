import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';

class AddressCell extends StatelessWidget {
  factory AddressCell.fromItem(WalletAddressListItem item,
          {@required bool isCurrent,
          @required bool isFirstAddress,
          @required Color backgroundColor,
          @required Color textColor,
          Function(String) onTap,
          Function() onEdit}) =>
      AddressCell(
          address: item.address,
          name: item.name,
          isCurrent: isCurrent,
          isFirstAddress: isFirstAddress,
          backgroundColor: backgroundColor,
          textColor: textColor,
          onTap: onTap,
          onEdit: onEdit);

  AddressCell(
      {@required this.address,
      @required this.name,
      @required this.isCurrent,
      @required this.isFirstAddress,
      @required this.backgroundColor,
      @required this.textColor,
      this.onTap,
      this.onEdit});

  final String address;
  final String name;
  final bool isCurrent;
  final bool isFirstAddress;
  final Color backgroundColor;
  final Color textColor;
  final Function(String) onTap;
  final Function() onEdit;

  String get label => name ?? address;

  @override
  Widget build(BuildContext context) {
    final Widget cell = InkWell(
        onTap: () => onTap(address),
        child: Container(
          color: backgroundColor,
          padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 28),
          child: Text(
            name ?? address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ));

    return (isCurrent || isFirstAddress)
        ? cell
        : Slidable(
            key: Key(address),
            actionPane: SlidableDrawerActionPane(),
            child: cell,
            secondaryActions: <Widget>[
                IconSlideAction(
                    caption: S.of(context).edit,
                    color: Colors.blue,
                    icon: Icons.edit,
                    onTap: () => onEdit?.call())
              ]);
  }
}
