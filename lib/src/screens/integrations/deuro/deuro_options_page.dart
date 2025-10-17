import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/info_chip.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/view_model/integrations/deuro_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DEuroOptionsPage extends BasePage {
  final DEuroViewModel _dEuroViewModel;

  DEuroOptionsPage(this._dEuroViewModel);

  @override
  String get title => "dEuro Protocol";

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  @override
  Widget body(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeTooltip(context, _dEuroViewModel.isFistTime));

    return Center(
      child: Container(
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: OptionTile(
                image: SvgPicture.asset(
                  "assets/images/deuro_savings.svg",
                  colorFilter:
                      ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn),
                ),
                title: "Savings",
                description: S.of(context).deuro_savings_subtitle,
                onPressed: () => Navigator.of(context).pushNamed(Routes.dEuroSavings),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: OptionTile(
                image: SvgPicture.asset(
                  "assets/images/deuro_borrowing.svg",
                  colorFilter:
                      ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn),
                ),
                title: S.of(context).deuro_borrowing,
                description: S.of(context).deuro_borrowing_subtitle,
                onPressed: () => Navigator.of(context).pushNamed(Routes.dEuroBorrowing),
              ),
            ),
            Spacer(),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InfoChip(
                      label: S.of(context).deuro_about_deuro,
                      icon: CupertinoIcons.info,
                      onPressed: () => _showWelcomeTooltip(context, true),
                    ),
                    SizedBox(width: 10),
                    InfoChip(
                      label: S.of(context).website,
                      icon: CupertinoIcons.globe,
                      onPressed: () => launchUrlString("https://deuro.com/"),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWelcomeTooltip(BuildContext context, bool isFistTime) async {
    if (!context.mounted || !isFistTime) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bottomSheetContext) => InfoBottomSheet(
        height: 350,
        titleText: "dEURO",
        titleIconPath: CryptoCurrency.deuro.iconPath,
        contentImage: 'assets/images/deuro_hero.png',
        contentImageSize: 200,
        content: S.of(context).deuro_savings_welcome_description,
        footerType: FooterType.doubleActionButton,
        doubleActionRightButtonText: S.of(context).close,
        rightActionButtonKey: ValueKey('deuro_page_tooltip_dialog_welcome_ok_button_key'),
        onRightActionButtonPressed: () => Navigator.of(bottomSheetContext).pop(),
        doubleActionLeftButtonText: S.of(context).learn_more,
        leftActionButtonKey: ValueKey('deuro_page_tooltip_dialog_welcome_learn_more_button_key'),
        onLeftActionButtonPressed: () => launchUrlString("https://deuro.com/what-is-deuro.html"),
        showDisclaimerText: _dEuroViewModel.isFistTime,
      ),
    );

    if (_dEuroViewModel.isFistTime) _dEuroViewModel.acceptDisclaimer();
  }
}
