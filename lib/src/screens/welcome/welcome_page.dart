import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/text_widgets/highlighted_text.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/gradient_background.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/src/widgets/scrollable_with_bottom_section.dart";
import "package:cake_wallet/utils/responsive_layout_util.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

class WelcomePage extends BasePage {
  static const aspectRatioImage = 1.5;
  final welcomeImageLight = "assets/new-ui/hero/welcome_wallet_light.svg";
  final welcomeImageDark = "assets/new-ui/hero/welcome_wallet_dark.svg";

  @override
  String? get title => S.current.wallet;

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (context, scaffold) => GradientBackground(scaffold: scaffold);

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget trailing(BuildContext context) {
    final Uri _url = Uri.parse("https://docs.cakewallet.com/get-started/setup/");
    return IconButton(
      icon: const Icon(
        Icons.info_outline,
        size: 26,
      ),
      onPressed: () async {
        await launchUrl(_url);
      },
    );
  }

  @override
  Widget body(BuildContext context) {
    final welcomeImage = currentTheme.isDark ? welcomeImageDark : welcomeImageLight;

    return ScrollableWithBottomSection(
      content: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(top: 64, bottom: 24, left: 24, right: 24),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: aspectRatioImage,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: CakeImageWidget(imageUrl: welcomeImage),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: HighlightedText(
                      text: S.of(context).welcome_subtitle_new_wallet,
                      highlightWord: S.of(context).create_new,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: HighlightedText(
                      text: S.of(context).welcome_subtitle_restore_wallet,
                      highlightWord: S.of(context).restore_existing_wallet,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomSection: Column(
        children: <Widget>[
          Text(
            "Please make selection below \nto create or recover your wallet.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: PrimaryButton(
              key: const ValueKey("welcome_page_restore_wallet_button_key"),
              onPressed: () {
                Navigator.pushNamed(context, Routes.restoreOptions, arguments: true);
              },
              text: S.of(context).restore_restore_wallet,
              color: Theme.of(context).colorScheme.surfaceContainer,
              textColor: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: PrimaryButton(
              key: const ValueKey("welcome_page_create_new_wallet_button_key"),
              onPressed: () => Navigator.pushNamed(context, Routes.newWalletFromWelcome),
              text: S.of(context).create_new,
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

}
