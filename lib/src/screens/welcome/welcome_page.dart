import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';

class WelcomePage extends BasePage {
  static const aspectRatioImage = 1.25;
  final welcomeImageLight = Image.asset('assets/images/welcome_light.png');
  final welcomeImageDark = Image.asset('assets/images/welcome.png');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme
            .of(context)
            .backgroundColor,
        resizeToAvoidBottomPadding: false,
        body: body(context));
  }

  @override
  Widget body(BuildContext context) {
    final welcomeImage = currentTheme.type == ThemeType.dark
        ? welcomeImageDark : welcomeImageLight;

    final newWalletImage = Image.asset('assets/images/new_wallet.png',
        height: 12,
        width: 12,
        color: Theme
            .of(context)
            .accentTextTheme
            .headline
            .decorationColor);
    final restoreWalletImage = Image.asset('assets/images/restore_wallet.png',
        height: 12,
        width: 12,
        color: Theme
            .of(context)
            .primaryTextTheme
            .title
            .color);

    return WillPopScope(onWillPop: () async => false, child: Container(
        padding: EdgeInsets.only(top: 64, bottom: 24, left: 24, right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            S
                                .of(context)
                                .welcome,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Theme
                                  .of(context)
                                  .accentTextTheme
                                  .display3
                                  .color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            S
                                .of(context)
                                .cake_wallet,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Theme
                                  .of(context)
                                  .primaryTextTheme
                                  .title
                                  .color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            S
                                .of(context)
                                .first_wallet_text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme
                                  .of(context)
                                  .accentTextTheme
                                  .display3
                                  .color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          S
                              .of(context)
                              .please_make_selection,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Theme
                                .of(context)
                                .accentTextTheme
                                .display3
                                .color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: PrimaryImageButton(
                            onPressed: () =>
                                Navigator.pushNamed(context,
                                    Routes.newWalletFromWelcome),
                            image: newWalletImage,
                            text: S
                                .of(context)
                                .create_new,
                            color: Theme
                                .of(context)
                                .accentTextTheme
                                .subtitle
                                .decorationColor,
                            textColor: Theme
                                .of(context)
                                .accentTextTheme
                                .headline
                                .decorationColor,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: PrimaryImageButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context,
                                      Routes.restoreOptions),
                              image: restoreWalletImage,
                              text: S
                                  .of(context)
                                  .restore_wallet,
                              color: Theme
                                  .of(context)
                                  .accentTextTheme
                                  .caption
                                  .color,
                              textColor: Theme
                                  .of(context)
                                  .primaryTextTheme
                                  .title
                                  .color),
                        )
                      ],
                    )
                  ],
                )
            )
          ],
        )
    ));
  }
}
