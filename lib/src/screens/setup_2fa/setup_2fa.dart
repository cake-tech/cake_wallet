import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
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
        Uri.parse('https://docs.cakewallet.com/features/advanced/authentication/');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
            child: AspectRatio(
              aspectRatio: 0.764,
              child: CakeImageWidget(imageUrl: 'assets/images/2fa.png'),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              S.current.setup_2fa_text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.571,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              HorizontalSectionDivider(margin: EdgeInsets.symmetric(horizontal: 24)),
              SettingsCellWithArrow(
                  title: cake2FAGuideTitle, handler: (_) => _launchUrl(cake2FAGuideUri)),
              HorizontalSectionDivider(margin: EdgeInsets.symmetric(horizontal: 24)),
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
