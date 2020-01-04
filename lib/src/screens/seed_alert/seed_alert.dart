import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';

class SeedAlert extends StatelessWidget {
  final imageSeed = Image.asset('assets/images/seedIco.png');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Theme.of(context).backgroundColor,
      body: SafeArea(
          child: Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    imageSeed,
                    Text(
                      S.of(context).seed_alert_first_text,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 19.0),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Text(
                      S.of(context).seed_alert_second_text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          letterSpacing: 0.2,
                          fontSize: 16.0,
                          color: Palette.lightBlue),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(children: <TextSpan>[
                          TextSpan(
                              text: S.of(context).seed_alert_third_text,
                              style: TextStyle(
                                  letterSpacing: 0.2,
                                  fontSize: 16.0,
                                  color: Palette.lightBlue)),
                          TextSpan(
                              text: S.of(context).seed_alert_settings,
                              style: TextStyle(
                                  letterSpacing: 0.2,
                                  fontSize: 16.0,
                                  color: Palette.lightGreen)),
                          TextSpan(
                              text: S.of(context).seed_alert_menu,
                              style: TextStyle(
                                  letterSpacing: 0.2,
                                  fontSize: 16.0,
                                  color: Palette.lightBlue)),
                        ]))
                  ],
                ),
              ),
            ),
            PrimaryButton(
                onPressed: () {},
                text: S.of(context).seed_alert_understand,
                color:
                    Theme.of(context).primaryTextTheme.button.backgroundColor,
                borderColor:
                    Theme.of(context).primaryTextTheme.button.decorationColor),
          ],
        ),
      )),
    );
  }
}
