import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/typography.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class IoniaWelcomePage extends BasePage {
  IoniaWelcomePage();

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.welcome_to_cakepay,
      style: textMediumSemiBold(
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              SizedBox(height: 90),
              Text(
                S.of(context).about_cake_pay,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Lato',
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ),
              ),
              SizedBox(height: 20),
              Text(
                S.of(context).cake_pay_account_note,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Lato',
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
                color: Theme.of(context).primaryColor,
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
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
