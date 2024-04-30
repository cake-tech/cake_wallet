import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Setup2FAPage extends BasePage {
  Setup2FAPage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  String get title => 'Cake 2FA';

  @override
  Widget body(BuildContext context) {
    final cake2FAGuideTitle = 'Cake 2FA Guide';
    final cake2FAGuideUri =
        Uri.parse('https://guides.cakewallet.com/docs/advanced-features/authentication');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
            child:
                AspectRatio(aspectRatio: 0.6, child: Image.asset('assets/images/setup_2fa_img.png')),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              S.current.setup_2fa_text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                height: 1.571,
                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              SettingsCellWithArrow(
                title: S.current.setup_totp_recommended,
                handler: (_) {
                  setup2FAViewModel.generateSecretKey();
                  return Navigator.of(context).pushReplacementNamed(Routes.setup_2faQRPage);
                },
              ),
              StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
              SettingsCellWithArrow(
                  title: cake2FAGuideTitle, handler: (_) => _launchUrl(cake2FAGuideUri)),
              StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
            ],
          ),
        ),
      ],
    );
  }

  static void _launchUrl(Uri url) async {
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {}
  }
}
