import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/pages/buy_sell/buy_sell_amount_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:flutter/material.dart';

enum BuySellPageMode { buy, sell }

class BuySellSelectorModal extends StatelessWidget {
  const BuySellSelectorModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceDim,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(spacing:24, mainAxisSize: MainAxisSize.min, children: [
          SizedBox.shrink(),
          Text(S.of(context).buy_or_sell, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),),
          Text(S.of(context).buy_or_sell_desc, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(spacing: 12,children: [
              BuySellSelectorModalButton(title: S.of(context).buy_crypto, description: S.of(context).buy_crypto_desc, iconPath: "assets/new-ui/plus.svg", onTap: ()=>openBuySellPage(context, BuySellPageMode.buy),),
              BuySellSelectorModalButton(title: S.of(context).sell_crypto, description: S.of(context).sell_crypto_desc, iconPath: "assets/new-ui/sell.svg", onTap: ()=>openBuySellPage(context, BuySellPageMode.sell))
            ],),
          ),
          SizedBox.shrink()
        ])
      )
    );
  }

  void openBuySellPage(BuildContext context, BuySellPageMode mode) {
    Navigator.of(context).pop();
    showModalBottomSheet(isScrollControlled: true, context: context, builder: (modalContext)=>ModalNavigator(rootPage: getIt.get<NewBuySellAmountPage>(param1: mode), parentContext: context,));
  }
}


class BuySellSelectorModalButton extends StatelessWidget {
  const BuySellSelectorModalButton({super.key, required this.title, required this.description, required this.iconPath, required this.onTap});

  final String title;
  final String description;
  final String iconPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 1,              color: Theme.of(context).colorScheme.surfaceContainerHigh,

          ),
          gradient: LinearGradient(
            colors: [
              context.customColors.cardGradientColorPrimary,
              context.customColors.cardGradientColorSecondary
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(padding: EdgeInsets.all(24), child: Row(spacing: 20, children: [

          CakeImageWidget(imageUrl: iconPath, width: 55, height: 55, colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant,BlendMode.srcIn),),
          Column(spacing: 8, crossAxisAlignment: CrossAxisAlignment.start,children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),),
            Text(description, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),)
          ],)

        ],),),

      ),
    );
  }
}
