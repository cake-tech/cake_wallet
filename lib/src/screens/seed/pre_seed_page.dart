import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class PreSeedPage extends BasePage {
  static final imageLight = Image.asset('assets/images/pre_seed_light.png');
  static final imageDark = Image.asset('assets/images/pre_seed_dark.png');

  @override
  Widget leading(BuildContext context) => null;

  @override
  String get title => 'IMPORTANT';

  @override
  Widget body(BuildContext context) {
    final image =
        getIt.get<SettingsStore>().isDarkTheme ? imageDark : imageLight;

    return Container(
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
                    padding:
                    EdgeInsets.only(top: 70, left: 16, right: 16),
                    child: Text(
                      'On the next page you will see a series of 25 words. This is your unique and private seed and it is the ONLY way to recover your wallet in case of loss or malfunction. It is YOUR responsibility to write it down and store it in a safe place outside of the Cake Wallet app.',
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
                      onPressed: () =>
                          Navigator.of(context).popAndPushNamed(Routes.seed,
                              arguments: true),
                      text: 'I understand. Show me my seed',
                      color: Theme.of(context)
                          .accentTextTheme
                          .body2
                          .color,
                      textColor: Colors.white)
                ],
              )
          )
        ],
      ),
    );
  }

}