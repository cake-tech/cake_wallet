import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/explainers/explainer_page.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class LightningDepositExplainer extends ExplainerPage {
  const LightningDepositExplainer({super.key});

  @override
  String get viewedPreferencesKey => PreferencesKey.lightningDepositExplainerViewed;

  @override
  String title(BuildContext context) => S.of(context).deposit_from_on_chain;

  @override
  String headline(BuildContext context) => S.of(context).lightning_deposit_explainer_headline;

  @override
  String subtitle(BuildContext context) => S.of(context).lightning_explainer_subtitle;

  @override
  String description(BuildContext context) => S.of(context).lightning_deposit_explainer_description;

  @override
  Widget illustration(BuildContext context) =>
      const CakeImageWidget(imageUrl: "assets/new-ui/lightning_deposit_explainer.svg");
}
