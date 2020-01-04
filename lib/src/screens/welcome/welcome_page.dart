import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/theme_changer.dart';
import 'package:cake_wallet/themes.dart';
import 'package:cake_wallet/generated/i18n.dart';

class WelcomePage extends BasePage {
  static const _aspectRatioImage = 1.26;
  static const _baseWidth = 411.43;
  final _image = Image.asset('assets/images/welcomeImg.png');
  final _cakeLogo = Image.asset('assets/images/cake_logo.png');

  @override
  Widget build(BuildContext context) {
    ThemeChanger _themeChanger = Provider.of<ThemeChanger>(context);
    bool _isDarkTheme = (_themeChanger.getTheme() == Themes.darkTheme);

    return Scaffold(
      backgroundColor:
          _isDarkTheme ? Theme.of(context).backgroundColor : backgroundColor,
      resizeToAvoidBottomPadding: false,
      body: SafeArea(child: body(context)),
    );
  }

  @override
  Widget body(BuildContext context) {
    final _screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = _screenWidth < _baseWidth ? 0.76 : 1.0;

    return Column(children: <Widget>[
      Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AspectRatio(
              aspectRatio: _aspectRatioImage,
              child: FittedBox(child: _image, fit: BoxFit.fill)),
          Positioned(bottom: 0.0, child: _cakeLogo)
        ],
      ),
      Expanded(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                S.of(context).welcome,
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                ),
                textScaleFactor: textScaleFactor,
                textAlign: TextAlign.center,
              ),
              Text(
                S.of(context).first_wallet_text,
                style: TextStyle(
                  fontSize: 22.0,
                  color: Palette.lightBlue,
                ),
                textScaleFactor: textScaleFactor,
                textAlign: TextAlign.center,
              ),
              Text(
                S.of(context).please_make_selection,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Palette.lightBlue,
                ),
                textScaleFactor: textScaleFactor,
                textAlign: TextAlign.center,
              )
            ]),
      ),
      Container(
          padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
          child: Column(children: <Widget>[
            PrimaryButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.newWalletFromWelcome);
                },
                text: S.of(context).create_new,
                color:
                    Theme.of(context).primaryTextTheme.button.backgroundColor,
                borderColor:
                    Theme.of(context).primaryTextTheme.button.decorationColor),
            SizedBox(height: 10),
            PrimaryButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.restoreOptions);
              },
              color: Theme.of(context).accentTextTheme.caption.backgroundColor,
              borderColor:
                  Theme.of(context).accentTextTheme.caption.decorationColor,
              text: S.of(context).restore_wallet,
            )
          ]))
    ]);
  }
}
