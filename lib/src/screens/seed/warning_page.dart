import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/view_model/advanced_privacy_settings_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';

class WarningPage extends BasePage {
  WarningPage(this.seedPhraseLength)
      : isPreSeedPage = seedPhraseLength != null,
        imageLight = Image.asset('assets/images/pre_seed_light.png'),
        imageDark = Image.asset('assets/images/pre_seed_dark.png');

  final Image imageDark;
  final Image imageLight;
  final int? seedPhraseLength;
  final bool isPreSeedPage;

  @override
  Widget? leading(BuildContext context) =>
      isPreSeedPage ? null : super.leading(context);

  @override
  String? get title => S.current.pre_seed_title;

  @override
  Widget body(BuildContext context) {
    final image = currentTheme.type == ThemeType.dark ? imageDark : imageLight;

    return WillPopScope(
        onWillPop: () async => !isPreSeedPage,
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.3),
                    child: AspectRatio(aspectRatio: 1, child: image),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                        isPreSeedPage
                            ? S.of(context).pre_seed_description(
                                seedPhraseLength.toString())
                            : S.of(context).setup_warning_2fa_text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            height: 1.7,
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Theme.of(context)
                                .extension<CakeTextTheme>()!
                                .secondaryTextColor)),
                  ),
                ),
                PrimaryButton(
                    onPressed: () => isPreSeedPage
                        ? Navigator.of(context)
                            .popAndPushNamed(Routes.seed, arguments: true)
                        : Navigator.of(context)
                            .popAndPushNamed(Routes.setup_2faPage),
                    text: isPreSeedPage
                        ? S.of(context).pre_seed_button_text
                        : S.of(context).understand,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white)
              ],
            ),
          ),
        ));
  }
}
