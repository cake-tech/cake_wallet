import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/themes.dart';
import 'package:cake_wallet/theme_changer.dart';

class WelcomePage extends BasePage {
  static const aspectRatioImage = 1.25;
  final welcomeImageLight = Image.asset('assets/images/welcome_light.png');
  final welcomeImageDark = Image.asset('assets/images/welcome.png');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        resizeToAvoidBottomPadding: false,
        body: SafeArea(child: body(context)));
  }

  @override
  Widget body(BuildContext context) {
    final _themeChanger = Provider.of<ThemeChanger>(context);
    final welcomeImage = _themeChanger.getTheme() == Themes.darkTheme
    ? welcomeImageDark : welcomeImageLight;

    final newWalletImage = Image.asset('assets/images/new_wallet.png',
        height: 12,
        width: 12,
        color: Palette.oceanBlue);
    final restoreWalletImage = Image.asset('assets/images/restore_wallet.png',
        height: 12,
        width: 12,
        color: Theme.of(context).primaryTextTheme.title.color);

    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          Flexible(
            flex: 2,
            child: AspectRatio(
              aspectRatio: aspectRatioImage,
              child: FittedBox(child: welcomeImage, fit: BoxFit.fill)
            )
          ),
          Flexible(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        S.of(context).welcome,
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).primaryTextTheme.caption.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        S.of(context).cake_wallet,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryTextTheme.title.color,
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
                          color: Theme.of(context).primaryTextTheme.caption.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    Text(
                      S.of(context).please_make_selection,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryTextTheme.caption.color,
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
                        textColor: Palette.oceanBlue,
                        borderColor: Palette.oceanBlue,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: PrimaryImageButton(
                          onPressed: () => Navigator.pushNamed(context, Routes.restoreOptions),
                          image: restoreWalletImage,
                          text: S.of(context).restore_wallet,
                          color: Theme.of(context).primaryTextTheme.overline.color,
                          textColor: Theme.of(context).primaryTextTheme.title.color),
                    )
                  ],
                )
              ],
            )
          )
        ],
      )
    );
  }
}
