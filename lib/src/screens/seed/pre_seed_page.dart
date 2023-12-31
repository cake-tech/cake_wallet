import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/InfoPage.dart';
import 'package:flutter/cupertino.dart';

class PreSeedPage extends InfoPage {
  PreSeedPage(this.seedPhraseLength);

  final int seedPhraseLength;

  @override
  bool get onWillPop => false;

  @override
  String get pageTitle => S.current.pre_seed_title;

  @override
  String get pageDescription =>
      S.current.pre_seed_description(seedPhraseLength.toString());

  @override
  String get buttonText => S.current.pre_seed_button_text;

  @override
  void Function(BuildContext) get onPressed => (BuildContext context) =>
      Navigator.of(context).popAndPushNamed(Routes.seed, arguments: true);
}
