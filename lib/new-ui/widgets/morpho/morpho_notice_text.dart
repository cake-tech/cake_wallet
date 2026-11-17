import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_terms_text.dart";
import "package:cake_wallet/routes.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

// disclosure required by Morpho's integration UX requirements:
// https://docs.morpho.org/developers/earn/vault-ux/ux-requirement/
class MorphoNoticeText extends StatelessWidget {
  const MorphoNoticeText({super.key});

  static final disclaimerUrl = Uri.https("morpho.org", "/disclaimers");

  @override
  Widget build(BuildContext context) => DefiTermsText(
        (linkPlaceholders) => S.of(context).morpho_notice(linkPlaceholders[0], linkPlaceholders[1]),
        links: [
          DefiTermsLink(
            S.of(context).cake_wallet_terms_of_use,
            () => Navigator.of(context).pushNamed(Routes.readDisclaimer),
          ),
          DefiTermsLink(
            S.of(context).morpho_disclaimer,
            () => launchUrl(disclaimerUrl, mode: LaunchMode.externalApplication),
          ),
        ],
      );
}
