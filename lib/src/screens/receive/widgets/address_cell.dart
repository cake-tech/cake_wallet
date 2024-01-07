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
      this.onEdit,
      this.txCount,
      this.balance,
      this.isChange = false});

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
          onEdit: onEdit,
          txCount: item.txCount,
          balance: item.balance,
          isChange: item.isChange);

  final String address;
  final String name;
  final bool isCurrent;
  final bool isPrimary;
  final Color backgroundColor;
  final Color textColor;
  final Function(String)? onTap;
  final Function()? onEdit;
  final int? txCount;
  final String? balance;
  final bool isChange;

  String get label {
    final formattedAddress = address.replaceAll('bitcoincash:', '');
    if (name.isEmpty){
      if(formattedAddress.length<=43){
        return formattedAddress;
      }else{
        return formattedAddress.substring(0,8)+'...'+
            formattedAddress.substring(formattedAddress.length-8,formattedAddress.length);
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
          width: double.infinity,
          color: backgroundColor,
          padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  if (txCount != null)
                  Text(
                    '$txCount ${S.of(context).transactions}',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  if (balance != null)
                    Text(
                      '$balance ${S.of(context).transactions}',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  if (isChange)
                    Text(
                      S.of(context).change,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ));
    return onEdit == null ? cell : Semantics(
      label: S.of(context).slidable,
      selected: isCurrent,
      enabled: !isCurrent,
      child: Slidable(
        key: Key(address),
        startActionPane: _actionPane(context),
        endActionPane: _actionPane(context),
        child: cell,
      ),
    );
  }

  ActionPane _actionPane(BuildContext context) => ActionPane(
    motion: const ScrollMotion(),
    extentRatio: 0.3,
    children: [
      SlidableAction(
        onPressed: (_) => onEdit?.call(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: Icons.edit,
        label: S.of(context).edit,
      ),
    ],
  );
}
