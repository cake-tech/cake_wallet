import "package:cake_wallet/entities/preferences_key.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/explainers/explainer_page.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

class GiftCardsExplainer extends ExplainerPage {
  const GiftCardsExplainer({super.key});

  @override
  String get viewedPreferencesKey => PreferencesKey.giftCardsExplainerViewed;

  @override
  String title(BuildContext context) => S.of(context).gift_cards_and_debit_cards;

  @override
  String headline(BuildContext context) => S.of(context).gift_cards_explainer_headline;

  @override
  String description(BuildContext context) => S.of(context).gift_cards_explainer_description;

  @override
  Widget illustration(BuildContext context) =>
      const CakeImageWidget(imageUrl: "assets/new-ui/gift_cards_explainer.svg");

  @override
  Widget attribution(BuildContext context) => Semantics(
        link: true,
        label: S.of(context).powered_by("Cake Pay"),
        excludeSemantics: true,
        child: GestureDetector(
          onTap: _openCakePay,
          child: Row(
            spacing: 12,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.of(context).powered_by_label,
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
              ),
              CakeImageWidget(
                imageUrl: "assets/new-ui/cake_pay_logo_mono.svg",
                width: 83.333,
                height: 25,
                colorFilter:
                    ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
              ),
              CakeImageWidget(
                imageUrl: "assets/new-ui/external_link.svg",
                width: 16,
                height: 16,
                colorFilter:
                    ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
              ),
            ],
          ),
        ),
      );

  Future<void> _openCakePay() async {
    try {
      await launchUrl(Uri.https("cakepay.com"), mode: LaunchMode.externalApplication);
    } catch (e) {
      printV(e);
    }
  }
}
