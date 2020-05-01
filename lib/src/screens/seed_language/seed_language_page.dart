import 'package:provider/provider.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/stores/seed_language/seed_language_store.dart';
import 'package:cake_wallet/src/screens/new_wallet/widgets/select_button.dart';
import 'package:cake_wallet/src/screens/seed_language/widgets/seed_language_picker.dart';

class SeedLanguage extends BasePage {
  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  Widget body(BuildContext context) => SeedLanguageForm();
}

class SeedLanguageForm extends StatefulWidget {
  @override
  SeedLanguageFormState createState() => SeedLanguageFormState();
}

class SeedLanguageFormState extends State<SeedLanguageForm> {
  static const aspectRatioImage = 1.22;
  final walletNameImage = Image.asset('assets/images/wallet_name.png');

  @override
  Widget build(BuildContext context) {
    final seedLanguageStore = Provider.of<SeedLanguageStore>(context);

    final List<String> seedLocales = [
      S.current.seed_language_english,
      S.current.seed_language_chinese,
      S.current.seed_language_dutch,
      S.current.seed_language_german,
      S.current.seed_language_japanese,
      S.current.seed_language_portuguese,
      S.current.seed_language_russian,
      S.current.seed_language_spanish
    ];

    return Container(
      color: PaletteDark.historyPanel,
      padding: EdgeInsets.only(top: 24),
      child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          content: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 12, right: 12),
                  child: AspectRatio(
                      aspectRatio: aspectRatioImage,
                      child: FittedBox(child: walletNameImage, fit: BoxFit.fill)),
                ),
                Padding(padding: EdgeInsets.only(top: 40),
                  child: Text(
                    S.of(context).seed_language_choose,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.only(top: 24),
                  child: Observer(
                      builder: (_) => SelectButton(
                          image: null,
                          text: seedLocales[seedLanguages.indexOf(seedLanguageStore.selectedSeedLanguage)],
                          color: PaletteDark.menuList,
                          textColor: Colors.white,
                          onTap: () async => await showDialog(
                              context: context,
                              builder: (BuildContext context) => SeedLanguagePicker()
                          )
                      )
                  ),
                )
              ]),
          bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          bottomSection: Observer(
            builder: (context) {
              return PrimaryButton(
                  onPressed: () =>
                      Navigator.of(context).popAndPushNamed(seedLanguageStore.currentRoute),
                  text: S.of(context).seed_language_next,
                  color: Colors.green,
                  textColor: Colors.white);
            },
          )),
    );
  }
}
