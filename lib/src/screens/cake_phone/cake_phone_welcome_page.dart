import 'package:cake_wallet/routes.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class CakePhoneWelcomePage extends BasePage {
  CakePhoneWelcomePage();

  @override
  Widget body(BuildContext context) => CakePhoneWelcomeBody();

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).welcome_to_cake_phone,
      style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'Lato',
          color: Theme.of(context).primaryTextTheme.headline6?.decorationColor),
    );
  }
}

class CakePhoneWelcomeBody extends StatefulWidget {
  CakePhoneWelcomeBody();

  @override
  CakePhoneWelcomeBodyState createState() => CakePhoneWelcomeBodyState();
}

class CakePhoneWelcomeBodyState extends State<CakePhoneWelcomeBody> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.fromLTRB(24, 100, 24, 20),
        content: Text(
          S.of(context).cake_phone_introduction,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).primaryTextTheme.headline6?.color,
            fontFamily: 'Lato',
          ),
        ),
        bottomSectionPadding: EdgeInsets.only(bottom: 24, right: 24, left: 24),
        bottomSection: Column(
          children: <Widget>[
            PrimaryButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.cakePhoneAuth);
              },
              text: S.of(context).create_account,
              color: Theme.of(context).accentTextTheme.bodyText1?.color,
              textColor: Colors.white,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 16),
              child: Text(
                S.of(context).already_have_account,
                style: TextStyle(
                  color: Theme.of(context).primaryTextTheme.headline6?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, Routes.cakePhoneAuth, arguments: true);
              },
              child: Text(
                S.of(context).login,
                style: TextStyle(
                  color: Theme.of(context).accentTextTheme.headline4?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
