import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/InfoPage.dart';
import 'package:flutter/cupertino.dart';

class Setup2FAInfoPage extends InfoPage {

  @override
  String get pageTitle => S.current.pre_seed_title;

  @override
  String get pageDescription => S.current.setup_warning_2fa_text;

  @override
  String get buttonText => S.current.understand;

  @override
  void Function(BuildContext) get onPressed => (BuildContext context) =>
      Navigator.of(context).popAndPushNamed(Routes.setup_2faPage);
}
