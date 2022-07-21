import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/typography.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class IoniaMoreOptionsPage extends BasePage {

   IoniaMoreOptionsPage(this.giftCard);
  
  final IoniaGiftCard giftCard;

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).more_options,
      style: textMediumSemiBold(
        color: Theme.of(context).accentTextTheme.display4.backgroundColor,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              S.of(context).choose_from_available_options,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: 'Lato',
                color: Theme.of(context).primaryTextTheme.title.color,
              ),
            ),
          ),
          SizedBox(height: 38),
          _IoniaOptionsItem(
            title: S.of(context).custom_redeem_amount,
            onTap: () => Navigator.pushNamed(context, Routes.ioniaCustomRedeemPage, 
              arguments: [giftCard],)
          ),
          SizedBox(height: 16),
          _IoniaOptionsItem(
            title: S.of(context).transfer,
            onTap: () => Navigator.pushNamed(context, Routes.ioniaTransferPage, 
              arguments: [giftCard],)
          ),
        ],
      ),
    );
  }
}

class _IoniaOptionsItem extends StatelessWidget {
  const _IoniaOptionsItem({
    @required this.title,
    @required this.onTap,
  });

  final String title; 
  final VoidCallback onTap;


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 40),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: [
            Theme.of(context).primaryTextTheme.subhead.color,
            Theme.of(context).primaryTextTheme.subhead.decorationColor,
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Text(title, style: textXLargeSemiBold(),),
      ),
    );
  }
}
