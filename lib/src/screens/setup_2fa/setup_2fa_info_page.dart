import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/Info_page.dart';
import 'package:flutter/cupertino.dart';

class Setup2FAInfoPage extends InfoPage {
  Setup2FAInfoPage()
      : super(
          imageLightPath: 'assets/images/2fa_warning_light.svg',
          imageDarkPath: 'assets/images/2fa_warning_dark.svg',
        );

  @override
  String get pageTitle => S.current.pre_seed_title;

  @override
  String get pageDescription => S.current.setup_warning_2fa_text;

  @override
  String get buttonText => S.current.understand;

  @override
  Key? get buttonKey => ValueKey('setup_2fa_info_page_button_key');

  @override
  void Function(BuildContext) get onPressed =>
      (BuildContext context) => Navigator.of(context).popAndPushNamed(Routes.setup_2faPage);
}
