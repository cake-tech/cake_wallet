import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';

class WelcomePage extends BasePage {
  static const aspectRatioImage = 1.5;
  final welcomeImageLight = 'assets/images/welcome_wallet_light.png';
  final welcomeImageDark = 'assets/images/welcome_wallet_dark.png';

  @override
  String? get title => S.current.wallet;

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
          (BuildContext context, Widget scaffold) => GradientBackground(scaffold: scaffold);

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget trailing(BuildContext context) {
    final Uri _url =
        Uri.parse('https://docs.cakewallet.com/get-started/setup/create-first-wallet/');
    return IconButton(
      icon: Icon(Icons.info_outline, size: 26,),
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
        padding: EdgeInsets.only(top: 64, bottom: 24, left: 24, right: 24),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
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
                    padding: EdgeInsets.only(top: 48),
                    child: highlightText(
                      context,
                      S.of(context).welcome_subtitle_new_wallet,
                      S.of(context).create_new,
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: highlightText(
                      context,
                      S.of(context).welcome_subtitle_restore_wallet,
                      S.of(context).restore_existing_wallet,
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
            'Please make selection below \nto create or recover your wallet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: EdgeInsets.only(top: 24),
            child: PrimaryButton(
              key: ValueKey('welcome_page_restore_wallet_button_key'),
              onPressed: () {
                Navigator.pushNamed(context, Routes.restoreOptions, arguments: true);
              },
              text: S.of(context).restore_restore_wallet,
              color: Theme.of(context).colorScheme.surfaceContainer,
              textColor: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: PrimaryButton(
              key: ValueKey('welcome_page_create_new_wallet_button_key'),
              onPressed: () => Navigator.pushNamed(context, Routes.newWalletFromWelcome),
              text: S.of(context).create_new,
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  RichText highlightText(BuildContext context, String text, String highlightWord) {
    final regex = RegExp(highlightWord, caseSensitive: false);
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
      );
    }

    List<InlineSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      final start = match.start;
      final end = match.end;

      if (start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, start),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
        ),
      );

      lastMatchEnd = end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }
}
