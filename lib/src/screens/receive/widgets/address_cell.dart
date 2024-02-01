import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
      this.isChange = false,
      this.hasBalance = false});

  factory AddressCell.fromItem(WalletAddressListItem item,
          {required bool isCurrent,
          required Color backgroundColor,
          required Color textColor,
          Function(String)? onTap,
          bool hasBalance = false,
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
          isChange: item.isChange,
          hasBalance: hasBalance);

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
  final bool hasBalance;

  static const int addressPreviewLength = 8;

  String get formattedAddress {
    final formatIfCashAddr = address.replaceAll('bitcoincash:', '');

    if (formatIfCashAddr.length <= (name.isNotEmpty ? 16 : 43)) {
      return formatIfCashAddr;
    } else {
      return formatIfCashAddr.substring(0, addressPreviewLength) +
          '...' +
          formatIfCashAddr.substring(formatIfCashAddr.length - addressPreviewLength, formatIfCashAddr.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget cell = InkWell(
        onTap: () => onTap?.call(address),
        child: Container(
          width: double.infinity,
          color: backgroundColor,
          padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        if (isChange)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Container(
                              height: 20,
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(8.5)),
                                  color: textColor),
                              alignment: Alignment.center,
                              child: Text(
                                S.of(context).unspent_change,
                                style: TextStyle(
                                  color: backgroundColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (name.isNotEmpty)
                          Text(
                            '$name - ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        Flexible(
                          child: AutoSizeText(
                            formattedAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isChange ? 10 : 14,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasBalance)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              'Balance: $balance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '${S.of(context).transactions.toLowerCase()}: $txCount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ));
    return onEdit == null
        ? cell
        : Semantics(
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
