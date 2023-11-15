import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';

class PreSeedPage extends BasePage {
  PreSeedPage(this.type)
      : imageLight = Image.asset('assets/images/pre_seed_light.png'),
        imageDark = Image.asset('assets/images/pre_seed_dark.png'),
        wordsCount = _wordsCount(type);

  final Image imageDark;
  final Image imageLight;
  final WalletType type;
  final int wordsCount;

  @override
  Widget? leading(BuildContext context) => null;

  @override
  String? get title => S.current.pre_seed_title;

  @override
  Widget body(BuildContext context) {
    final image = currentTheme.type == ThemeType.dark ? imageDark : imageLight;

    return WillPopScope(
        onWillPop: () async => false,
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3
                  ),
                  child: AspectRatio(aspectRatio: 1, child: image),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    S.of(context).pre_seed_description(wordsCount.toString()),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor),
                  ),
                ),
                PrimaryButton(
                    onPressed: () =>
                        Navigator.of(context).popAndPushNamed(Routes.seed, arguments: true),
                    text: S.of(context).pre_seed_button_text,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white)
              ],
            ),
          ),
        ));
  }

  static int _wordsCount(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return 25;
      case WalletType.ethereum:
      case WalletType.bitcoinCash:
        return 12;
      default:
        return 24;
    }
  }
}
