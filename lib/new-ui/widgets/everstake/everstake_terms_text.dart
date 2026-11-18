import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_terms_text.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

class EverstakeTermsText extends StatelessWidget {
  const EverstakeTermsText(this.acceptance, {super.key});

  final String Function(String terms) acceptance;

  @override
  Widget build(BuildContext context) => DefiTermsText(
        (linkPlaceholders) => acceptance(linkPlaceholders.single),
        links: [
          DefiTermsLink(
            S.of(context).everstake_terms,
            () => launchUrl(
              Uri.https("everstake.com", "/terms-of-use"),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      );
}
