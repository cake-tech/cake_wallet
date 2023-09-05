import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/src/widgets/seed_language_selector.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/screens/seed_language/widgets/seed_language_picker.dart';

class SeedLanguage extends BasePage {
  SeedLanguage({required this.onConfirm});

  final Function(BuildContext, String) onConfirm;

  final walletNameImage = Image.asset('assets/images/wallet_name.png');
  final walletNameLightImage =
  Image.asset('assets/images/wallet_name_light.png');

  @override
  String get title => S.current.wallet_list_restore_wallet;

  @override
  Widget body(BuildContext context) =>
      SeedLanguageForm(
          onConfirm: onConfirm,
          walletImage: currentTheme.type == ThemeType.dark
              ? walletNameImage : walletNameLightImage);
}

class SeedLanguageForm extends StatefulWidget {
  SeedLanguageForm({required this.onConfirm, required this.walletImage});

  final Function(BuildContext, String) onConfirm;
  final Image walletImage;

  @override
  SeedLanguageFormState createState() => SeedLanguageFormState();
}

class SeedLanguageFormState extends State<SeedLanguageForm> {
  static const aspectRatioImage = 1.22;
  final _languageSelectorKey = GlobalKey<SeedLanguageSelectorState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 24),
      child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
          content:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Padding(
              padding: EdgeInsets.only(left: 12, right: 12),
              child: AspectRatio(
                  aspectRatio: aspectRatioImage,
                  child: FittedBox(child: widget.walletImage,
                      fit: BoxFit.fill)),
            ),
            Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text(
                S.of(context).seed_language_choose,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color:
                        Theme.of(context).extension<CakeTextTheme>()!.titleColor),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: SeedLanguageSelector(
                  key: _languageSelectorKey,
                  initialSelected: defaultSeedLanguage),
            )
          ]),
          bottomSectionPadding:
              EdgeInsets.only(left: 24, right: 24, bottom: 24),
          bottomSection: Observer(
            builder: (context) {
              return PrimaryButton(
                  onPressed: () => widget.onConfirm(
                      context, _languageSelectorKey.currentState!.selected),
                  text: S.of(context).seed_language_next,
                  color: Colors.green,
                  textColor: Colors.white);
            },
          )),
    );
  }
}
