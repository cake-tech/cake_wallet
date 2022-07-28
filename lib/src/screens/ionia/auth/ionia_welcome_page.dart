import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/view_model/ionia/ionia_gift_cards_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:mobx/mobx.dart';

class IoniaWelcomePage extends BasePage {
  IoniaWelcomePage(this._cardsListViewModel);

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.welcome_to_cakepay,
      style: textMediumSemiBold(
        color: Theme.of(context).accentTextTheme.display4.backgroundColor,
      ),
    );
  }

  final IoniaGiftCardsListViewModel _cardsListViewModel;

  @override
  Widget body(BuildContext context) {
    reaction((_) => _cardsListViewModel.isLoggedIn, (bool state) {
      if (state) {
        Navigator.pushReplacementNamed(context, Routes.ioniaManageCardsPage);
      }
    });
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              SizedBox(height: 100),
              Text(
                S.of(context).about_cake_pay,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Lato',
                  color: Theme.of(context).primaryTextTheme.title.color,
                ),
              ),
              SizedBox(height: 20),
              Text(
                S.of(context).cake_pay_account_note,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Lato',
                  color: Theme.of(context).primaryTextTheme.title.color,
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              PrimaryButton(
                text: S.of(context).create_account,
                onPressed: () => Navigator.of(context).pushNamed(Routes.ioniaCreateAccountPage),
                color: Theme.of(context).accentTextTheme.body2.color,
                textColor: Colors.white,
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                S.of(context).already_have_account,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Lato',
                  color: Theme.of(context).primaryTextTheme.title.color,
                ),
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: () => Navigator.of(context).pushNamed(Routes.ioniaLoginPage),
                child: Text(
                  S.of(context).login,
                  style: TextStyle(
                    color: Palette.blueCraiola,
                    fontSize: 18,
                     letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: 20)
            ],
          )
        ],
      ),
    );
  }
}
