import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomePage extends BasePage {
  static const aspectRatioImage = 1.25;
  final welcomeImageLight = Image.asset('assets/images/wallet_type_light.png');
  final welcomeImageDark = Image.asset('assets/images/wallet_type.png');

  @override
  String? get title => S.current.wallet;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget trailing(BuildContext context) {
    final Uri _url = Uri.parse('https://docs.cakewallet.com/get-started/setup/create-first-wallet/');
    return IconButton(
      icon: Icon(Icons.info_outline),
      onPressed: () async {
        await launchUrl(_url);
      },
    );
  }

  @override
  Widget body(BuildContext context) {
    final welcomeImage = currentTheme.type == ThemeType.dark ? welcomeImageDark : welcomeImageLight;

    final newWalletImage = Image.asset('assets/images/new_wallet.png',
        height: 12,
        width: 12,
        color: Theme.of(context).colorScheme.onPrimary);
    final restoreWalletImage = Image.asset('assets/images/restore_wallet.png',
        height: 12, width: 12, color: Theme.of(context).colorScheme.onSurface);

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
                    child: FittedBox(child: welcomeImage, fit: BoxFit.contain),
                  ),
                  Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: highlightText(context, S.of(context).welcome_subtitle_new_wallet,
                          S.of(context).create_new)),
                  SizedBox(height: 10),
                  Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: highlightText(context, S.of(context).welcome_subtitle_restore_wallet,
                          S.of(context).restore_existing_wallet)),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomSection: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 24),
            child: PrimaryImageButton(
                key: ValueKey('welcome_page_restore_wallet_button_key'),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.restoreOptions, arguments: true);
                },
                image: restoreWalletImage,
                text: S.of(context).restore_existing_wallet,
                color: Theme.of(context).cardColor,
                textColor: Theme.of(context).colorScheme.onSurface),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: PrimaryImageButton(
              key: ValueKey('welcome_page_create_new_wallet_button_key'),
              onPressed: () => Navigator.pushNamed(context, Routes.newWalletFromWelcome),
              image: newWalletImage,
              text: S.of(context).create_new,
              color: Theme.of(context).colorScheme.primaryContainer,
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
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
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    List<InlineSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      final start = match.start;
      final end = match.end;

      if (start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, start),
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(start, end),
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastMatchEnd = end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ));
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }
}
