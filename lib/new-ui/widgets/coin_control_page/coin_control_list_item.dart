import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_simple_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CoinControlListItem extends StatelessWidget {
  CoinControlListItem({
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
    this.onCheckBoxTap,
  });

  final String note;
  final String amount;
  final String fiatAmount;
  final String address;
  final bool isSending;
  final bool isFrozen;
  final bool isChange;
  final bool isSilentPayment;
  final bool isFirst;
  final bool isLast;
  final bool isLoading;
  final Function()? onCheckBoxTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height:70,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(12) : Radius.circular(0),
          bottom: isLast ? Radius.circular(12) : Radius.circular(0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 8),
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
                    Text(amount, style: TextStyle(fontSize:14,fontWeight: FontWeight.w400,color: Theme.of(context).colorScheme.onSurface),),
                    AutoSizeText(
                      '${address.substring(0, 5)}...${address.substring(address.length - 5)}',
                      style: TextStyle(fontSize:12,fontWeight: FontWeight.w400,color: Theme.of(context).colorScheme.onSurfaceVariant),
                      maxLines: 1,
                    ),
                  ],

                )
              ],
            ),
            SvgPicture.asset("assets/new-ui/arrow_right.svg", colorFilter:ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),)
          ],
        ),
      )
    );
  }

  Widget _getLeading(BuildContext context) {
    if(isLoading) {
      return CircularProgressIndicator(color: Theme.of(context).colorScheme.primary,);
    }

    if(isFrozen) {
      return SvgPicture.asset("assets/new-ui/frozen.svg");
    }

    return NewSimpleCheckbox(value: isSending, onChanged: (value){onCheckBoxTap?.call();});

  }
}
