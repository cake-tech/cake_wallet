import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/seed_language/widgets/seed_language_picker.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/src/stores/seed_language/seed_language_store.dart';

class SeedLanguage extends BasePage {
  final imageSeed = Image.asset('assets/images/seedIco.png');

  @override
  Widget body(BuildContext context) {
    final seedLanguageStore = Provider.of<SeedLanguageStore>(context);

    return Container(
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
                    S.of(context).seed_language_choose,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16.0),
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  SeedLanguagePicker(),
                ],
              ),
            ),
          ),
          PrimaryButton(
              onPressed: () =>
                  Navigator.of(context).popAndPushNamed(seedLanguageStore.currentRoute),
              text: S.of(context).seed_language_next,
              color:
              Theme.of(context).primaryTextTheme.button.backgroundColor,
              textColor:
              Theme.of(context).primaryTextTheme.button.color),
        ],
      ),
    );
  }
}
