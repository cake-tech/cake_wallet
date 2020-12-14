import 'package:cake_wallet/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class PreSeedPage extends BasePage {
  final imageLight = Image.asset('assets/images/pre_seed_light.png');
  final imageDark = Image.asset('assets/images/pre_seed_dark.png');

  @override
  Widget leading(BuildContext context) => null;

  @override
  String get title => S.current.pre_seed_title;

  @override
  Widget body(BuildContext context) {
    final image = currentTheme.isDarkTheme ? imageDark : imageLight;

    return WillPopScope(
        onWillPop: () async => false,
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Flexible(
                  flex: 2,
                  child: AspectRatio(
                      aspectRatio: 1,
                      child: FittedBox(child: image, fit: BoxFit.contain))),
              Flexible(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 70, left: 16, right: 16),
                        child: Text(
                          S.of(context).pre_seed_description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .caption
                                  .color),
                        ),
                      ),
                      PrimaryButton(
                          onPressed: () => Navigator.of(context)
                              .popAndPushNamed(Routes.seed, arguments: true),
                          text: S.of(context).pre_seed_button_text,
                          color: Theme.of(context).accentTextTheme.body2.color,
                          textColor: Colors.white)
                    ],
                  ))
            ],
          ),
        ));
  }
}
