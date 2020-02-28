import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/src/stores/seed_language/seed_language_store.dart';
import 'package:cake_wallet/src/widgets/present_picker.dart';

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
                    style: TextStyle(fontSize: 19.0),
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  Observer(
                      builder: (_) => InkWell(
                        onTap: () => _setSeedLanguage(context),
                        child: Text(seedLanguageStore.selectedSeedLanguage,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 19.0, color: Palette.lightBlue),
                        ),
                      )),
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
              borderColor:
              Theme.of(context).primaryTextTheme.button.decorationColor),
        ],
      ),
    );
  }

  Future<void> _setSeedLanguage(BuildContext context) async {
    final seedLanguageStore = Provider.of<SeedLanguageStore>(context);
    final selectedSeedLanguage =
    await presentPicker(context, seedLanguages);

    if (selectedSeedLanguage != null) {
      seedLanguageStore.setSelectedSeedLanguage(selectedSeedLanguage);
    }
  }
}
