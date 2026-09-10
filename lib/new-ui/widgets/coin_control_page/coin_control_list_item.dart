import "package:auto_size_text/auto_size_text.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_simple_checkbox.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";

class CoinControlListItem extends StatelessWidget {
  const CoinControlListItem({
    required this.note,
    required this.amount,
    required this.fiatAmount,
    required this.address,
    required this.isSending,
    required this.isFrozen,
    required this.isChange,
    required this.isSilentPayment,
    required this.isFirst,
    required this.isLast,
    required this.isLoading,
    required this.hasCheckbox,
    this.onCheckBoxTap,
  });

  final String note;
  final Money amount;
  final Money? fiatAmount;
  final String address;
  final bool isSending;
  final bool isFrozen;
  final bool isChange;
  final bool isSilentPayment;
  final bool isFirst;
  final bool isLast;
  final bool isLoading;
  final bool hasCheckbox;
  final Function()? onCheckBoxTap;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(12) : Radius.zero,
            bottom: isLast ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 12,
                children: [
                  _getLeading(context),
                  // NewSimpleCheckbox(value: isSending, onChanged: (value){onCheckBoxTap?.call();}),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 4,
                    children: [
                      Row(
                        spacing: 4,
                        children: [
                          MoneyText(
                            amount,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (address.toLowerCase().contains("mweb")) // hack carried over from old ui, we really should just have a boolean in the object
                            CakeImageWidget(
                              imageUrl: "assets/new-ui/address-type-picker-icons/mweb.svg",
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                  Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
                            ),
                          if (isSilentPayment)
                            CakeImageWidget(
                              imageUrl: "assets/new-ui/address-type-picker-icons/silent.svg",
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                  Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
                            ),
                        ],
                      ),
                      AutoSizeText(
                        "${address.substring(0, 5)}...${address.substring(address.length - 5)}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                spacing: 8,
                children: [
                  if (fiatAmount != null)
                    MoneyText(
                      fiatAmount!,
                      trimZeros: false,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  CakeImageWidget(
                    imageUrl: "assets/new-ui/arrow_right.svg",
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
                  ),
                ],
              )
            ],
          ),
        ),
    );
  }

  Widget _getLeading(BuildContext context) {
    if (isLoading) {
      return CircularProgressIndicator(color: Theme.of(context).colorScheme.primary);
    }

    if (isFrozen) {
      return const CakeImageWidget(imageUrl: "assets/new-ui/frozen.svg");
    }

    if (!hasCheckbox) {
      return const SizedBox.shrink();
    }

    return NewSimpleCheckbox(
      value: isSending,
      onChanged: (value) => onCheckBoxTap?.call(),
    );
  }
}
