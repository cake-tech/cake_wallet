import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/Info_page.dart';
import 'package:flutter/cupertino.dart';

class PreSeedPage extends InfoPage {
  PreSeedPage()
      : super(
          imageLightPath: 'assets/images/seed_warning_light.svg',
          imageDarkPath: 'assets/images/seed_warning_dark.svg',
        );

  @override
  bool get onWillPop => false;

  @override
  String get pageTitle => S.current.pre_seed_title;

  @override
  String get pageDescription => S.current.pre_seed_description;

  @override
  String get buttonText => S.current.pre_seed_button_text;

  @override
  Key? get buttonKey => ValueKey('pre_seed_page_button_key');

  @override
  void Function(BuildContext) get onPressed =>
      (BuildContext context) => Navigator.of(context).pushNamed(Routes.seed, arguments: true);
}
