import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';

class AddressCell extends StatelessWidget {
  AddressCell(
      {required this.address,
      required this.name,
      required this.isCurrent,
      required this.isPrimary,
      required this.backgroundColor,
      required this.textColor,
      this.onTap,
      this.onEdit});

  factory AddressCell.fromItem(WalletAddressListItem item,
          {required bool isCurrent,
          required Color backgroundColor,
          required Color textColor,
          Function(String)? onTap,
          Function()? onEdit}) =>
      AddressCell(
          address: item.address,
          name: item.name ?? '',
          isCurrent: isCurrent,
          isPrimary: item.isPrimary,
          backgroundColor: backgroundColor,
          textColor: textColor,
          onTap: onTap,
          onEdit: onEdit);

  final String address;
  final String name;
  final bool isCurrent;
  final bool isPrimary;
  final Color backgroundColor;
  final Color textColor;
  final Function(String)? onTap;
  final Function()? onEdit;

  String get label {
    if (name.isEmpty){
      if(address.length<=16){
        return address;
      }else{
        return address.substring(0,8)+'...'+
            address.substring(address.length-8,address.length);
      }
    }else{
      return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget cell = InkWell(
        onTap: () => onTap?.call(address),
        child: Container(
          color: backgroundColor,
          padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 28),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ));
    // FIX-ME: Slidable
    return cell;
    // return Container(
    //       color: backgroundColor,
    //       child: Slidable(
    //         key: Key(address),
    //         actionPane: SlidableDrawerActionPane(),
    //         child: cell,
    //         secondaryActions: <Widget>[
    //             IconSlideAction(
    //                 caption: S.of(context).edit,
    //                 color: Colors.blue,
    //                 icon: Icons.edit,
    //                 onTap: () => onEdit?.call())
    //           ]));
  }
}
