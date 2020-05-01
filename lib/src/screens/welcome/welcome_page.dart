import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class WelcomePage extends BasePage {
  static const aspectRatioImage = 1.25;
  final welcomeImage = Image.asset('assets/images/welcome.png');
  final newWalletImage = Image.asset('assets/images/new_wallet.png', height: 12, width: 12, color: PaletteDark.historyPanel);
  final restoreWalletImage = Image.asset('assets/images/restore_wallet.png', height: 12, width: 12, color: Colors.white);

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        resizeToAvoidBottomPadding: false,
        body: SafeArea(child: body(context)));
  }

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 20),
      color: PaletteDark.historyPanel,
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(bottom: 20),
        content: Column(
          children: <Widget>[
            AspectRatio(
              aspectRatio: aspectRatioImage,
              child: FittedBox(child: welcomeImage, fit: BoxFit.fill)),
            Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    S.of(context).welcome,
                    style: TextStyle(
                      fontSize: 18,
                      color: PaletteDark.walletCardText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      S.of(context).cake_wallet,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Text(
                      S.of(context).first_wallet_text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: PaletteDark.walletCardText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 20),
        bottomSection: Column(children: <Widget>[
          Text(
            S.of(context).please_make_selection,
            style: TextStyle(
              fontSize: 12,
              color: PaletteDark.walletCardText,
            ),
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: EdgeInsets.only(top: 24),
            child: PrimaryImageButton(
                onPressed: () => Navigator.pushNamed(context, Routes.newWalletFromWelcome),
                image: newWalletImage,
                text: S.of(context).create_new,
                color: Colors.white,
                textColor: PaletteDark.historyPanel),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: PrimaryImageButton(
                onPressed: () => Navigator.pushNamed(context, Routes.restoreOptions),
                image: restoreWalletImage,
                text: S.of(context).restore_wallet,
                color: PaletteDark.historyPanelButton,
                textColor: Colors.white),
          )
        ]),
      ),
    );
  }
}
