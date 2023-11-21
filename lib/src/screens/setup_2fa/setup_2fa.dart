import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';

import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';

import '../../widgets/standard_list.dart';

class Setup2FAPage extends BasePage {
  Setup2FAPage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  String get title => S.current.setup_2fa;

  @override
  Widget body(BuildContext context) {
    final cake2FAGuideTitle = 'Cake 2FA Guide';
    final cake2FAGuideUri =
    Uri.parse('https://guides.cakewallet.com/docs/advanced-features/authentication');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.current.important_note,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.571,
                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  S.current.setup_2fa_text,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.571,
                    color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 56),
          SettingsCellWithArrow(
            title: S.current.setup_totp_recommended,
            handler: (_) {
              setup2FAViewModel.generateSecretKey();
              return Navigator.of(context).pushReplacementNamed(Routes.setup_2faQRPage);
            },
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SettingsCellWithArrow(
              title: cake2FAGuideTitle,
              handler: (_) => Navigator.of(context)
                  .pushNamed(Routes.webViewPage, arguments: [cake2FAGuideTitle, cake2FAGuideUri])),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        ],
      ),
    );
  }
}
