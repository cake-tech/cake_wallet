import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:flutter/material.dart';

class UnspentCoinsListItem extends StatelessWidget {
  UnspentCoinsListItem({
    required this.note,
    required this.amount,
    required this.address,
    required this.isSending,
    required this.isFrozen,
    required this.isChange,
    required this.isSilentPayment,
    this.onCheckBoxTap,
  });

  final String note;
  final String amount;
  final String address;
  final bool isSending;
  final bool isFrozen;
  final bool isChange;
  final bool isSilentPayment;
  final Function()? onCheckBoxTap;

  @override
  Widget build(BuildContext context) {
    final unselectedItemColor = Theme.of(context).colorScheme.surfaceContainer;
    final selectedItemColor = Theme.of(context).colorScheme.primary;
    final itemColor = isSending ? selectedItemColor : unselectedItemColor;
    final amountColor = isSending
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;
    final addressColor = isSending
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        color: itemColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: StandardCheckbox(
              iconColor: amountColor,
              borderColor: addressColor,
              value: isSending,
              onChanged: (value) => onCheckBoxTap?.call(),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note.isNotEmpty)
                          AutoSizeText(
                            note,
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: amountColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                          ),
                        AutoSizeText(
                          amount,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: amountColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        )
                      ],
                    ),
                    if (isFrozen)
                      Container(
                        height: 17,
                        padding: EdgeInsets.only(left: 6, right: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8.5)),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          S.of(context).frozen,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                fontWeight: FontWeight.w600,
                                color: itemColor,
                                fontSize: 8,
                              ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AutoSizeText(
                        '${address.substring(0, 5)}...${address.substring(address.length - 5)}', // ToDo: Maybe use address label
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: addressColor,
                        ),
                        maxLines: 1,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (isChange)
                            Container(
                              height: 17,
                              padding: EdgeInsets.only(left: 6, right: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(8.5)),
                                color: Theme.of(context).colorScheme.primaryContainer,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                S.of(context).unspent_change,
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 8,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                            ),
                          if (address.toLowerCase().contains("mweb"))
                            Container(
                              height: 17,
                              padding: EdgeInsets.only(left: 6, right: 6),
                              margin: EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.5),
                                ),
                                color: Theme.of(context).colorScheme.primaryContainer,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "MWEB",
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 8,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                            ),
                          if (isSilentPayment)
                            Container(
                              height: 17,
                              padding: EdgeInsets.only(left: 6, right: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(8.5)),
                                color: Theme.of(context).colorScheme.primaryContainer,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                S.of(context).silent_payments,
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 8,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
