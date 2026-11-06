import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_notice_text.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

// Brand & attribution based on morpho docs
class MorphoBadge extends StatelessWidget {
  const MorphoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final onDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: S.of(context).powered_by("Morpho"),
      hint: S.of(context).opens_in_browser,
      onTap: _openDisclaimer,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _openDisclaimer,
        child: CakeImageWidget(
          imageUrl: onDark
              ? "assets/new-ui/powered_by_morpho_dark.svg"
              : "assets/new-ui/powered_by_morpho_light.svg",
          height: 20,
        ),
      ),
    );
  }

  static void _openDisclaimer() =>
      launchUrl(MorphoNoticeText.disclaimerUrl, mode: LaunchMode.externalApplication);
}
