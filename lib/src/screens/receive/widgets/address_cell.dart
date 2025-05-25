import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class AddressCell extends StatelessWidget {
  AddressCell({
    required this.address,
    required this.name,
    required this.isCurrent,
    required this.isPrimary,
    required this.backgroundColor,
    required this.textColor,
    required this.walletType,
    required this.currentTheme,
    this.onTap,
    this.onEdit,
    this.onHide,
    this.isHidden = false,
    this.onDelete,
    this.txCount,
    this.balance,
    this.isChange = false,
    this.hasBalance = false,
    this.hasReceived = false,
  });

  factory AddressCell.fromItem(
    WalletAddressListItem item, {
    required bool isCurrent,
    required Color backgroundColor,
    required Color textColor,
    required WalletType walletType,
    required MaterialThemeBase currentTheme,
    Function(String)? onTap,
    bool hasBalance = false,
    bool hasReceived = false,
    Function()? onEdit,
    Function()? onHide,
    bool isHidden = false,
    Function()? onDelete,
  }) =>
      AddressCell(
        address: item.address,
        name: item.name ?? '',
        isCurrent: isCurrent,
        isPrimary: item.isPrimary,
        backgroundColor: backgroundColor,
        textColor: textColor,
        walletType: walletType,
        currentTheme: currentTheme,
        onTap: onTap,
        onEdit: onEdit,
        onHide: onHide,
        isHidden: isHidden,
        onDelete: onDelete,
        txCount: item.txCount,
        balance: item.balance,
        isChange: item.isChange,
        hasBalance: hasBalance,
        hasReceived: hasReceived,
      );

  final String address;
  final String name;
  final bool isCurrent;
  final bool isPrimary;
  final Color backgroundColor;
  final Color textColor;
  final WalletType walletType;
  final MaterialThemeBase currentTheme;
  final Function(String)? onTap;
  final Function()? onEdit;
  final Function()? onHide;
  final bool isHidden;
  final Function()? onDelete;
  final int? txCount;
  final String? balance;
  final bool isChange;
  final bool hasBalance;
  final bool hasReceived;

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
                      mainAxisAlignment: name.isNotEmpty
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Row(
                          children: [
                            if (isChange)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Container(
                                  height: 20,
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(8.5)),
                                    color: textColor,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    S.of(context).unspent_change,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: backgroundColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                            if (name.isNotEmpty)
                              Text(
                                '$name',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                              ),
                          ],
                        ),
                        Flexible(
                          child: AddressFormatter.buildSegmentedAddress(
                            address: address,
                            walletType: walletType,
                            shouldTruncate: name.isNotEmpty || address.length > 43,
                            evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: isChange ? 10 : 14,
                                  color: textColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (hasBalance || hasReceived)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              '${hasReceived ? S.of(context).received : S.of(context).balance}: $balance',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                            ),
                            Text(
                              '${S.of(context).transactions.toLowerCase()}: $txCount',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
              startActionPane: _actionPaneStart(context),
              endActionPane: _actionPaneEnd(context),
              child: cell,
            ),
          );
  }

  ActionPane _actionPaneEnd(BuildContext context) => ActionPane(
        motion: const ScrollMotion(),
        extentRatio: onDelete != null ? 0.4 : 0.3,
        children: [
          SlidableAction(
            onPressed: (_) => onHide?.call(),
            backgroundColor: isHidden
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            icon: isHidden ? CupertinoIcons.arrow_left : CupertinoIcons.arrow_right,
            label: isHidden ? S.of(context).show : S.of(context).hide,
          ),
        ],
      );

  ActionPane _actionPaneStart(BuildContext context) => ActionPane(
        motion: const ScrollMotion(),
        extentRatio: onDelete != null ? 0.4 : 0.3,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit?.call(),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            icon: Icons.edit,
            label: S.of(context).edit,
          ),
          if (onDelete != null)
            SlidableAction(
              onPressed: (_) => onDelete!.call(),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              icon: Icons.delete,
              label: S.of(context).delete,
            ),
        ],
      );
}
